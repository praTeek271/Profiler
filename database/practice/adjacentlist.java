public class  adjacentlist{
    static class edge{    //edge class
        int src;
        int dest;

        public edge(int s,int d){   //constructor
            this.src=s;
            this.dest=d;
        }
    }


    public static void createGraph(ArrayList<edge> graph){
        for(int i=0; i<graph.size();i++){
            graph[i]= new ArrayList<edge>();   // explaination: we are creating an array of arraylist of edge class, so we need to initialize each index of the array with a new arraylist of edge class
        }

        graph[0].add(new edge(0,1));
        graph[0].add(new edge(0,2));
        
        graph[1].add(new edge(1,3));
        graph[1].add(new edge(1,0));

        graph[2].add(new edge(2,0));
        graph[2].add(new edge(2,4));

        graph[3].add(new edge(3,4));
        graph[3].add(new edge(3,5));
        
        graph[4].add(new edge(4,3));
        graph[4].add(new edge(4,5));

        graph[5].add(new edge(5,3));
        graph[5].add(new edge(5,4));
        graph[5].add(new edge(5,6));

        graph[6].add(new edge(6,5));
    }

    public void main(String[] args){
        int v= Integer.parseInt(args[0]);     //input vertex from user
        System.out.print("Enter the vertex number: ");
        int a= Integer.parseInt(args[0]);
        ArrayList<edge> graph= new ArrayList<edge>(v);   //create an arraylist of edge class with size v
        createGraph(graph);   //call the createGraph method to initialize the graph

        for (int i=0; i<graph[a].size();i++){
            edge e=graph[a].get(i);   //get the edge at index i of the arraylist at index a of the graph
            System.out.println(e.dest);
        }

    }

}
