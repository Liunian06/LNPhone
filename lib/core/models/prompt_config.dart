class PromptConfig {
  final String roleplayPrompt;
  final String realityPrompt;
  final String text2ImagePrompt;
  final bool enableRealityPrompt;
  final int contextLength;

  const PromptConfig({
    this.roleplayPrompt = '',
    this.realityPrompt = '',
    this.text2ImagePrompt = '',
    this.enableRealityPrompt = true,
    this.contextLength = 10,
  });
}
