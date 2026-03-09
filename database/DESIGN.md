# 🧠 Custom Graph Engine Design

## 1. Core Data Structures

### A. Adjacency List (The "Graph")
Used to store relationships between entities.
- **Nodes**: Patients, Doctors.
- **Edges**: `HAS_ACCESS` (Directed graph).

```typescript
type NodeId = string;
type EdgeType = 'HAS_ACCESS' | 'OWNS_PROFILE';

interface GraphNode {
  id: NodeId;
  data: any;
  outgoing: Map<NodeId, EdgeType>; // Adjacency List
}
```

### B. B-Tree (The "Index")
Used for O(log n) retrieval of records by SHN.
- **Node Structure**: Keys sorted, multiple children per node.
- **Operations**: `insert`, `search`.

### C. Write-Ahead Log (The "Persistence")
- Format: `[TIMESTAMP] [OP] [KEY] [VALUE]`
- Replay mechanism on startup.

## 2. Learning Goals
1.  **Memory Management**: How to handle thousands of nodes without leaking memory.
2.  **Traversal Algorithms**: BFS for "Shortest Path" (not relevant here) vs DFS for "Path Existence" (Access Check).
3.  **Correctness**: Ensuring the Tree stays balanced (if implementing AVL/Red-Black or B-Tree).

## 3. Interfaces
```typescript
interface GraphEngine {
  addNode(id: string, data: any): void;
  addEdge(from: string, to: string, type: string): void;
  findPath(from: string, to: string): boolean; // DFS
}
```
