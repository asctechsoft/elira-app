enum EditorTool {
  adjust,
  filters,
  crop,
  retouch,
  remove,
  background,
  effects,
  text,
  ai,
}

extension EditorToolX on EditorTool {
  String get label => switch (this) {
        EditorTool.adjust => 'Adjust',
        EditorTool.filters => 'Filters',
        EditorTool.crop => 'Crop',
        EditorTool.retouch => 'Retouch',
        EditorTool.remove => 'Remove',
        EditorTool.background => 'BG',
        EditorTool.effects => 'Effects',
        EditorTool.text => 'Text',
        EditorTool.ai => 'AI',
      };
}
