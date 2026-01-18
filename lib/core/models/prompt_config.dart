class PromptConfig {
  final String roleplayPrompt;
  final String realityPrompt;
  final bool enableRealityPrompt;
  final int contextLength;

  const PromptConfig({
    this.roleplayPrompt = '',
    this.realityPrompt = '',
    this.enableRealityPrompt = true,
    this.contextLength = 10,
  });
}
