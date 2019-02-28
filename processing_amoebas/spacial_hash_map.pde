class SpatialHashMap<T> {
  private final int cellWidth;
  private final int cellHeight;
  private final int cellsW;
  private final int cellsH;
  private final ArrayList<T> grid[];
  
  class GridCoord {
    int x;
    int y;
    GridCoord(final int x, final int y) {
      this.x = x;
      this.y = y;
    }
  }
  
  SpatialHashMap(final int cellWidth, final int cellHeight, final int realWidth, final int realHeight) {
    this.cellWidth = cellWidth;
    this.cellHeight = cellHeight;
    this.cellsW = realWidth / cellWidth;
    this.cellsH = realHeight / cellHeight;
    grid = new ArrayList[cellsW * cellsH];
    for (int k = 0; k < cellsW * cellsH; k++) {
      grid[k] = new ArrayList<T>();
    }
  }

  void clear() {
    for (int k = 0; k < cellsW * cellsH; k++) {
      grid[k].clear();
    }
  }
  
  GridCoord worldToGridCoords(final float x, final float y) {
    float gridX = Math.min(Math.max(Math.round(x / cellWidth), 0), cellsW - 1);
    float gridY = Math.min(Math.max(Math.round(y / cellHeight), 0), cellsH - 1);   
    return new GridCoord((int)gridX, (int)gridY);
  }
  
  private int worldToGridIndex(final float x, final float y) {
    final GridCoord coords = worldToGridCoords(x, y);
    return gridCoordsToIndex(coords.x, coords.y);
  }
  
  private int gridCoordsToIndex(final int x, final int y) {
    return Math.round(x * cellsH + y);
  }

  void add(final float x, final float y, final T data) {
    final int index = worldToGridIndex(x, y);
    grid[index].add(data);
  }

  ArrayList<T> query(final float x, final float y, final float radius) {
    return queryWithRadius(x, y, radius);
  }

  ArrayList<T> query(final float x, final float y) {
    final int index = worldToGridIndex(x, y);
    return grid[index];
  }
  
  private ArrayList<T> queryWithGridCoords(final int x, final int y) {
    final int index = gridCoordsToIndex(x, y);
    return grid[index];
  }

  ArrayList<T> queryWithRadius(final float x, final float y, final float radius) {
    final GridCoord coords = worldToGridCoords(x, y);

    final float radiusW = radius / this.cellWidth;
    final float radiusH = radius  / this.cellHeight;
    
    final int left = Math.max(Math.round(coords.x - radiusW), 0);
    final int right = Math.min(Math.round(coords.x + radiusW), cellsW - 1);
    final int bottom = Math.max(Math.round(coords.y - radiusH), 0);
    final int top = Math.min(Math.round(coords.y + radiusH), cellsH - 1);

    final ArrayList<T> result = new ArrayList<T>();

    for (int i = left; i <= right; i++) {
      for (int j = bottom; j <= top; j++) {
        final ArrayList<T> query = queryWithGridCoords(i, j);
        for (int k = 0; k < query.size(); k++) {
          result.add(query.get(k));
        }
      }
    }

    return result;
  }
}
