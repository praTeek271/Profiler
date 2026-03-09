class edge:
    def __init__(self,src,dst):
        self.src=src
        self.dst=dst
        # self.wt=weight

#----------------------------------------------------------------------------
# -------------------------***Graph creation***------------------------------
def createGraph(v):
    
    #     1------3
    #    /       | \
    #   0        |  5--6
    #    \       | /
    #     2------4

    graph=[[] for i in range(v)]
    # adding edges
    graph[0].append(edge(0,1))
    graph[0].append(edge(0,2))
    
    graph[1].append(edge(1,0))
    graph[1].append(edge(1,3))

    graph[2].append(edge(2,0))
    graph[2].append(edge(2,4))

    graph[3].append(edge(3,1))
    graph[3].append(edge(3,4))
    graph[3].append(edge(3,5))

    graph[4].append(edge(4,2))
    graph[4].append(edge(4,3))
    graph[4].append(edge(4,5))

    graph[5].append(edge(5,3))
    graph[5].append(edge(5,4))
    graph[5].append(edge(5,6))

    graph[6].append(edge(5,6))

    return graph


def createDisconnectedGraph(v):
    graph=[[] for i in range(v)]
 
    # adding edges
    graph[0].append(edge(0,1))
    # graph[0].append(edge(0,2))
    
    graph[1].append(edge(1,0))
    graph[1].append(edge(1,3))

    # graph[2].append(edge(2,0))
    graph[2].append(edge(2,4))

    graph[3].append(edge(3,1))
    # graph[3].append(edge(3,4))
    # graph[3].append(edge(3,5))

    graph[4].append(edge(4,2))
    # graph[4].append(edge(4,3))
    graph[4].append(edge(4,5))

    # graph[5].append(edge(5,3))
    # graph[5].append(edge(5,4))
    graph[5].append(edge(5,6))

    graph[6].append(edge(6,5))

    return graph

def createCyclicGraph(v):
    """
       1----->3
       |      |
       0      5
       |      |
       2<-----4
    """

    graph=[[] for i in range(v)]
 
    # adding edges
    graph[0].append(edge(0,1))
    
    graph[1].append(edge(1,3))

    graph[3].append(edge(3,5))

    graph[5].append(edge(5,4))

    graph[4].append(edge(4,2))

    graph[2].append(edge(2,0))

    return graph

# ----------------------------------------------------------------------------
def bfs(graph,src, visited):
    vis=visited
    que=[]
    que.append(src)
    while len(que)>0:
        curr=que.pop(0)
        if (vis[curr]==False):
            print(curr,end=" ")
            vis[curr]=True
            # add neighbors to the queue
            for i in graph[curr]:
                e=i.dst
                que.append(e)


def dfs(graph,src, visited):
    print(src,end=" ")
    visited[src]=True
    for i in graph[src]:
        e=i.dst
        if visited[e]==False:
            dfs(graph,e,visited)

def printGraph(graph):
    for i in range(len(graph)):
        for j in graph[i]:
            print(f"[{j.src}]------ [{j.dst}]",end=" ; ")
        print()

def printneighbor(graph,src):
    try:
        for i in graph[src]:
            print(f"[{i.src}]------ [{i.dst}]",end=" ; ")
        print()
    except IndexError:
        print("Invalid source entered")

def allpath(graph, vis, curr, strpath, tar):

    # base case
    if curr== tar:
        print(strpath)
        return

    for i in graph[curr]:
        if vis[i.dst]==False:
            vis[curr]=True
            allpath(graph,vis,i.dst,strpath+str(i.dst),tar)
            vis[curr]=False


def iscyclicDirected(graph, vis, curr, recstack):
    vis[curr]= True
    recstack[curr]= True

    for i in graph[curr]:  # iterate on neightbors of curr
        if (recstack[i.dst]==True):
            return True  # cycle detected
        elif (not vis[i.dst]):
                if iscyclicDirected(graph,vis,i.dst,recstack):
                    return True
    recstack[curr]= False
    return False

def main():
    v=6
    graph=createCyclicGraph(v)

    # printneighbor(graph, int(input("Enter the source vertex: ")))
    visited=[False for i in range(v)]
    print("printing cycles in the graph: ")
    recstack=[False for i in range(v)]
    
    if iscyclicDirected(graph,visited,0,recstack):
        print("cycle detected") 
    else:
        print("cycle not detected")

if __name__=="__main__":
    main()