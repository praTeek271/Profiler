# 🧠 Custom Graph Engine Design (Learning Phase)

This folder is your playground for building a custom database engine from scratch.

## 🎯 Learning Objectives
1.  **B-Tree**: Implement a balanced tree structure for indexing.
2.  **Adjacency List**: Model relationships between Patients and Doctors.
3.  **Graph Traversal**: Use DFS or BFS to verify "Doctor -> Patient" access.
4.  **Persistence**: Use a Write-Ahead Log (WAL) to ensure data survives restarts.

## 📁 Suggested Structure
- `src/btree.ts`: Your indexing logic.
- `src/graph.ts`: The relationship logic.
- `src/wal.ts`: File persistence logic.
- `test/`: Your test scripts (e.g., using `ts-node`).

## 🛠 Setup Tips
To run your TS files directly, use `ts-node`:
`pnpx ts-node src/graph.ts` (or `npx`).

Happy coding! I'll be here whenever you're ready to integrate this into the `backend`.
