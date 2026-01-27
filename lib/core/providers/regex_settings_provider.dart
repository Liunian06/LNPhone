import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/regex_rule_model.dart';
import '../database/database.dart';

class RegexSettingsProvider extends ChangeNotifier {
  final AppDatabase _db;
  List<RegexRule> _rules = [];
  bool _isInitialized = false;

  RegexSettingsProvider(this._db) {
    _loadRules();
  }

  List<RegexRule> get rules => _rules;
  bool get isInitialized => _isInitialized;

  Future<void> _loadRules() async {
    try {
      final rulesJson = await _db.getSetting('regex_rules');
      if (rulesJson != null) {
        final List<dynamic> decoded = jsonDecode(rulesJson);
        final savedRules = decoded.map((e) => RegexRule.fromJson(e)).toList();

        // 检查是否有缺失的默认规则并自动补全
        final defaultRules = _getDefaultRules();
        bool modified = false;

        for (final defaultRule in defaultRules) {
          final index = savedRules.indexWhere((r) => r.id == defaultRule.id);
          if (index == -1) {
            savedRules.add(defaultRule);
            modified = true;
          } else {
            // 强制同步默认规则的 order，确保顺序正确
            if (savedRules[index].order != defaultRule.order) {
              savedRules[index] =
                  savedRules[index].copyWith(order: defaultRule.order);
              modified = true;
            }
          }
        }

        _rules = savedRules;
        // 确保按 order 排序
        _rules.sort((a, b) => a.order.compareTo(b.order));

        // 如果顺序发生了变化，重新分配连续的 order 以防冲突
        if (modified) {
          for (int i = 0; i < _rules.length; i++) {
            _rules[i] = _rules[i].copyWith(order: i);
          }
          await _saveRules();
        }
      } else {
        // 初始化默认规则
        _rules = _getDefaultRules();
        await _saveRules();
      }
    } catch (e) {
      debugPrint('Error loading regex rules: $e');
      // 出错时使用默认规则
      _rules = _getDefaultRules();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveRules() async {
    try {
      final rulesJson = jsonEncode(_rules.map((e) => e.toJson()).toList());
      await _db.setSetting('regex_rules', rulesJson);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving regex rules: $e');
    }
  }

  List<RegexRule> _getDefaultRules() {
    return [
      const RegexRule(
        id: 'default_code_block',
        name: '代码块提取',
        pattern: r'^```(?:json)?\s*([\s\S]*?)\s*```$',
        replacement: r'$1',
        type: RegexRuleType.regex,
        order: 0,
      ),
      const RegexRule(
        id: 'default_wrap_array',
        name: 'JSON 数组包裹',
        pattern: r'^(\{[\s\S]*\})$',
        replacement: r'[$1]',
        type: RegexRuleType.regex,
        order: 1,
      ),
      const RegexRule(
        id: 'default_missing_comma',
        name: '缺少逗号修复',
        pattern: r'\}\s*\{',
        replacement: '},{',
        type: RegexRuleType.regex,
        order: 2,
      ),
      const RegexRule(
        id: 'default_trailing_comma',
        name: '尾随逗号修复',
        pattern: r',\s*([\]}])',
        replacement: r'$1',
        type: RegexRuleType.regex,
        order: 3,
      ),
      const RegexRule(
        id: 'default_xml_output',
        name: 'XML 标签提取',
        pattern: r'<output>(.*?)</output>',
        replacement: r'$1',
        type: RegexRuleType.regex,
        order: 4,
      ),
      const RegexRule(
        id: 'default_id_check',
        name: 'ID 格式校验',
        pattern: r'^\d{4}$',
        replacement: '', // 校验规则通常不用于替换，这里仅占位，实际逻辑在 Parser 中处理
        type: RegexRuleType.regex,
        order: 5,
        isEnabled: true, // 默认开启，但在 Parser 中可能有特殊处理逻辑
      ),
      const RegexRule(
        id: 'default_remove_spaces',
        name: '去空格',
        pattern: ' ',
        replacement: '',
        type: RegexRuleType.replace,
        order: 6,
        isEnabled: false, // 默认关闭
      ),
    ];
  }

  Future<void> addRule(RegexRule rule) async {
    _rules.add(rule);
    await _saveRules();
  }

  Future<void> updateRule(RegexRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      _rules[index] = rule;
      await _saveRules();
    }
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((r) => r.id == id);
    await _saveRules();
  }

  Future<void> reorderRules(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final RegexRule item = _rules.removeAt(oldIndex);
    _rules.insert(newIndex, item);

    // 更新所有规则的 order
    for (int i = 0; i < _rules.length; i++) {
      _rules[i] = _rules[i].copyWith(order: i);
    }

    await _saveRules();
  }

  Future<void> resetToDefault() async {
    _rules = _getDefaultRules();
    await _saveRules();
  }

  /// 应用所有启用的规则处理文本
  /// 注意：某些规则（如 ID 校验）可能需要在特定上下文中使用，这里主要处理通用的文本替换/提取
  String processText(String text) {
    String result = text;

    for (final rule in _rules) {
      if (!rule.isEnabled) continue;

      // 跳过 ID 校验规则，因为它不是文本替换规则
      if (rule.id == 'default_id_check') continue;

      try {
        if (rule.type == RegexRuleType.replace) {
          result = result.replaceAll(rule.pattern, rule.replacement);
        } else {
          // 正则处理
          final regex = RegExp(rule.pattern,
              caseSensitive: false, multiLine: true, dotAll: true);

          // 特殊处理提取类正则（如代码块提取、XML提取）
          // 如果正则包含捕获组且替换内容引用了捕获组（如 $1），则尝试匹配并替换
          // 如果是纯粹的替换（如修复逗号），直接 replaceAll

          if (rule.replacement.contains(r'$')) {
            // 尝试匹配，如果匹配成功则提取/替换，否则保持原样
            // 对于提取类（如代码块），通常是全匹配替换
            if (regex.hasMatch(result)) {
              // 注意：这里简单使用 replaceAllMapped 可能不适用于提取整个内容的场景
              // 如果是提取整个内容（如 ^...$），replaceAllMapped 可以工作
              // 但如果是局部修复（如逗号），也可以工作
              result = result.replaceAllMapped(regex, (match) {
                String replacement = rule.replacement;
                for (int i = 0; i <= match.groupCount; i++) {
                  replacement =
                      replacement.replaceAll('\$$i', match.group(i) ?? '');
                }
                return replacement;
              });
            }
          } else {
            result = result.replaceAll(regex, rule.replacement);
          }
        }
      } catch (e) {
        debugPrint('Error applying rule ${rule.name}: $e');
        // 忽略错误，继续处理下一条规则
      }
    }

    return result;
  }
}
