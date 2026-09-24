/// What an AI tool needs from the user before it can run.
enum AiToolInput {
  /// The photo alone.
  image,

  /// The photo plus a text prompt (outpainting, object replacement).
  imageAndPrompt,
}

/// One cloud tool. [id] is sent to our backend and stored in the edit stack,
/// so it is API: a [name] can be reworded freely, an id cannot.
class AiTool {
  const AiTool({
    required this.id,
    required this.name,
    required this.tagline,
    required this.credits,
    this.input = AiToolInput.image,
    this.minEdge = 256,
  });

  final String id;
  final String name;
  final String tagline;

  /// What one run costs. Shown before the run, charged by the server.
  final int credits;

  final AiToolInput input;

  /// Below this the upscalers and face models have nothing to work with, so
  /// the run is refused locally rather than spending credits to fail.
  final int minEdge;

  bool get needsPrompt => input == AiToolInput.imageAndPrompt;

  @override
  String toString() => 'AiTool($id)';
}

class AiTools {
  const AiTools._();

  static const enhance = AiTool(
    id: 'ai_enhance',
    name: 'AI Enhance',
    tagline: 'Sharper & clearer',
    credits: 4,
  );

  static const removeBackground = AiTool(
    id: 'remove_bg',
    name: 'Remove BG',
    tagline: 'Clean & precise',
    credits: 5,
  );

  static const retouch = AiTool(
    id: 'ai_retouch',
    name: 'AI Retouch',
    tagline: 'Natural skin',
    credits: 8,
    minEdge: 512,
  );

  static const removeObject = AiTool(
    id: 'remove_object',
    name: 'Remove Object',
    tagline: 'Erase anything',
    credits: 5,
  );

  static const expand = AiTool(
    id: 'expand',
    name: 'Expand',
    tagline: 'Bigger horizons',
    credits: 10,
    input: AiToolInput.imageAndPrompt,
  );

  static const replace = AiTool(
    id: 'replace',
    name: 'Replace',
    tagline: 'Swap anything',
    credits: 10,
    input: AiToolInput.imageAndPrompt,
  );

  static const relight = AiTool(
    id: 'relight',
    name: 'Relight',
    tagline: 'Perfect lighting',
    credits: 6,
  );

  static const restore = AiTool(
    id: 'restore',
    name: 'Restore',
    tagline: 'Fix & revive',
    credits: 8,
  );

  static const headshot = AiTool(
    id: 'headshot',
    name: 'Headshot',
    tagline: 'Studio quality',
    credits: 12,
    minEdge: 512,
  );

  static const productShot = AiTool(
    id: 'product',
    name: 'Product Studio',
    tagline: 'For business',
    credits: 12,
  );

  static const List<AiTool> all = [
    enhance,
    removeBackground,
    retouch,
    removeObject,
    expand,
    replace,
    relight,
    restore,
    headshot,
    productShot,
  ];

  /// Unknown ids resolve to null rather than throwing: a job saved by a newer
  /// build must not crash the history.
  static AiTool? byId(String id) {
    for (final tool in all) {
      if (tool.id == id) return tool;
    }
    return null;
  }
}
