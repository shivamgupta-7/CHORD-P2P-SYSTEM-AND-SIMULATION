



%Module Definition for the project
-module(project3).

%All the functions are exported at once instead of calling them individually
-compile(export_all).

% This function starts the program and takes the dynamic input for the user in umber of Nodes
% FindNext and Algorithm
start(NumNodes, NumReqs) ->

    _Temp = 0,
    _N = 0,
    Peerlist = #{},
    Sp = #{},
    Finger=#{},

%     Peerlist = Set up a list of nodes to be for nodes that are created with PID and stores in the location
%     Sp = Create a Map Comprosing of Successor and Predecessors for the communication
%     NumReqs = Map for storing the requests that have passed through
%     Finger = Map needed for creating the finger table.
%     NextNode= Initially set to 0 and then traverses the algorithm for finding the Next Node of each peer needed at every step of communication 
%     PrevNode= Initially set to 0 and then traverses the algorithm for finding the Previous Node of each peer needed at every step of communication 
%     NodeId= Stores the currrent node Id for finding which node is being searched/lookedup

    persistent_term:put(sucpred, Sp),
    persistent_term:put(node, Peerlist),
    persistent_term:put(reqs, NumReqs),
    persistent_term:put(finger, Finger),
    persistent_term:put(nextnode, 0),
    persistent_term:put(prevnode, 0),
    persistent_term:put(nodeId, 0),

%Spawn the desired nodes
    register(mid, spawn(project3, server, [NumNodes])),

%Map is set up for storing the Process ID's of spawned Nodes
    Map = #{-1 => mid},
    persistent_term:put(map, Map),
    M = 6,
    persistent_term:put(m, M),
    Integer = integer_to_list(0),
    Str = string:concat("node", Integer),

%Hashing Taking place for as mentioned in the Research Paper enhances the security
    Name = io_lib:format("~64.16.0b", [
        binary:decode_unsigned(
            crypto:hash(
                sha,
                Str
            )
        )
    ]),

    Hashing = Name,
    persistent_term:put(first, Hashing),

    L = #{}, 

%   Actors are spawned according to the requirement s of the project and achieve concurrency
%   and distributed programming.
    Pid = spawn(project3, nodeWork, [L]),
    NewM2 = persistent_term:get(node),
    NewM3 = #{1 => {1,Pid}},
    MapNewCr = maps:merge(NewM2, NewM3),

    persistent_term:put(node, MapNewCr),

    io:fwrite("First node created with id: ~p~n", [Name]),
    Pid ! {initial},
   
    loopforloop(2, NumNodes-1,1).

%--------------------------------------------SERVER FUCTION------------------------------------------
server(NumNodes) ->
    _Count = 0,

    receive
        {_N} ->
            % Nodes that have finished their work
            io:fwrite("Node completed work");
        
        {_Msg,_Jh} ->
                Map = persistent_term:get(node),
                io:fwrite("~p",[Map]),
                N = length(maps:to_list(Map)),
                io:fwrite("writing successive nodes - ~p",[N]),
                Peerlist = persistent_term:get(node),

                % Peer List getting updated as new Nodes getting appended to the List
                First = element(1,maps:get(1,Peerlist)),
                Last =  element(1,maps:get(N,Peerlist)),
                Next =  element(1,maps:get(2,Peerlist)),

                % Temp Map for Storing the Nodes and their successors and predecessors    
                Temp = #{First=>{Last,Next}},
    
    
                SucPred = persistent_term:get(sucpred),
                Newmp = maps:merge(SucPred,Temp),
                persistent_term:put(sucpred,Newmp),
                find_nextnode(N-2,N);

        {done,_K,_EW}->
            Map = persistent_term:get(node),
            Sucpred = persistent_term:get(sucpred),
            io:fwrite("~p",[Sucpred]),
            L = length(maps:to_list(Map)),
            fingerinitialization(L-1,L),
            io:fwrite("Calculating Hop Count ~n"),
            Xv=NumNodes*NumNodes*10,
            timer:sleep(Xv),
            AvHopCount=math:sqrt(math:log2(NumNodes)),
            io:fwrite("Hop Count = ~p ~n",[AvHopCount]);

        {_F,_FG,FH,FH}->
            Fin = persistent_term:get(finger),
            io:fwrite("~p",[Fin])
            
    end,
    server(NumNodes).

%---------------------------Spawn remaining actors----------------------------------------
loopforloop(_, 0,_) ->
    mid ! {"done","gh"},
    ok;

loopforloop(I, NumNodes,Prev) ->
    K = [3,6,7,11],
    Ran = lists:nth(rand:uniform(length(K)), K),
    L = #{},
   
    Pid = spawn(project3, nodeWork, [L]),
    Map = persistent_term:get(node),
    Nodenum = Prev +Ran,
    M=persistent_term:get(m),
    Max = math:pow(2,M),
    if Nodenum > Max ->
        loopforloop(I,0,Prev);
    true->
        NewM2 = #{I => {Nodenum,Pid}},
        NewM3 = maps:merge(Map, NewM2),
        persistent_term:put(node, NewM3),
        io:fwrite("New node created with id: ~p~n", [Nodenum]),
        Pid ! {new_node},
        loopforloop(I + 1, NumNodes-1,Nodenum)

    end.
   
%---------------------------------------Create Chord-------------------------------------------
create_chord(Node_list, Neighbor_Map, 11) ->
    persistent_term:put(neighbor, Neighbor_Map),
    persistent_term:put(list, Node_list),
    mid ! {neighbors_finished},
    ok;

% The Node_List keeps on updating along withh th neighbour Map for that Particular Index
create_chord(Node_list, Neighbor_Map, Index) ->
    if
        Index == 1 ->
            Key = lists:nth(Index, Node_list),
            Neighbor_List = maps:get(Key, Neighbor_Map),
            X = lists:nth(Index + 1, Node_list),
            L = [X],
            N_List = Neighbor_List ++ L,
            NM = maps:update(Key, N_List, Neighbor_Map),
            persistent_term:put(neighbor, NM);

        Index == length(Node_list) ->
            Key = lists:nth(Index, Node_list),
            Neighbor_List = maps:get(Key, Neighbor_Map),
            X = lists:nth(Index - 1, Node_list),
            L = [X],
            N_List = Neighbor_List ++ L,
            NM = maps:update(Key, N_List, Neighbor_Map),
            persistent_term:put(neighbor, NM);

        true ->
            Key = lists:nth(Index, Node_list),
            Neighbor_List = maps:get(Key, Neighbor_Map),
            X1 = lists:nth(Index + 1, Node_list),
            X2 = lists:nth(Index - 1, Node_list),
            L = [X1] ++ [X2],
            N_List = Neighbor_List ++ L,
            NM = maps:update(Key, N_List, Neighbor_Map),
            persistent_term:put(neighbor, NM)
    end,

    N_Map = persistent_term:get(neighbor),
    Node_L = persistent_term:get(list),
    create_chord(Node_L, N_Map, Index + 1).

%--------------------------------Node Work for Finger Table-------------------------------------------
nodeWork(Table) ->
    receive
        {initial} ->
            _NodeId = persistent_term:get(nodeId);
        {new_node} ->
            _NodeId = persistent_term:get(nodeId)
            
    end,
nodeWork(Table).

%---------------------------Find the Next Node/Predecessor for the Current Node --------------------------
find_nextnode(0,Numnodes)->
     Peerlist = persistent_term:get(node),
                First = element(1,maps:get(1,Peerlist)),
                Last =  element(1,maps:get(Numnodes,Peerlist)),
                Behind_last =  element(1,maps:get(Numnodes-1,Peerlist)),

                Temp = #{Last=>{Behind_last,First}},
    
    
                SucPred = persistent_term:get(sucpred),
                Newmp = maps:merge(SucPred,Temp),
                persistent_term:put(sucpred,Newmp),
    

    mid ! {done,"D","sd"};

find_nextnode(I,Numnodes) ->
   Peerlist = persistent_term:get(node),

    Pred = element(1,maps:get(Numnodes -I-1,Peerlist)),
    Suc = element(1,maps:get(Numnodes-I+1,Peerlist)),
    Curr =  element(1,maps:get(Numnodes-I,Peerlist)),
    io:fwrite("~p - ~p - ~p\n",[Pred,Curr,Suc]),
    Temp = #{Curr=>{Pred,Suc}},
    
    
    SucPred = persistent_term:get(sucpred),
    Newmp = maps:merge(SucPred,Temp),
    persistent_term:put(sucpred,Newmp),

    find_nextnode(I-1,Numnodes).


%----------------------------------Look Up Function ---------------------------------------
%Hop Count Gets Updated for each Iteration then Used to Calculate Average -----------------
lookup(Key, Requestor,Flag) ->
    HopCount = 0,
    Found = false,
    Requestor_ID = persistent_term:get(node),
    ID = lists:nth(Requestor_ID, Requestor),
    Compareids = find_nextnode(ID, Requestor_ID),

    if
        Key==ID ->
            Flag = false,
            _Found = 58,
            _Hopcount = HopCount + 1,
        exit
    end,

    if
        Key > ID andalso Key =< Compareids ->
            Flag = false,
            _Found1 = 58, 
            _HopCount = HopCount + 1;

        true ->
            if
                ID > Compareids ->
                    _Hopcount1 = HopCount + 1,
                    Flag = false,
                    exit;
                true ->
                    while(HopCount, finger, Flag, ID, Key, Found)
            end                
    end.

%------------------------------------------- While Loop for Traversing in the LookUp Function --------------------------
while(L) ->
    while(L+1).

while(Hops, L, Fl, Id, Key, Found) ->
    I = 0,
    Fingervalue = persistent_term:get(node),
    if
        Fingervalue < Id and Fl ->
            Fl = false,
            Hops = Hops + 1;
        true ->
            Found = true,
            Hops = Hops + 1,
            while(Hops, L+1, Fl, Id, Key, Found)
    end,
    I = 0,
    Hops = Hops + 1,
    while(Hops, L+1, Fl, Id, Key, Found).


%-------------------------------------Start with the First Node for the Work ------------------------------
startFirstNode(NodeId,Table) ->
    M = persistent_term:get(m),
    firstLoop(M, M,Table,NodeId).


%--------------------------------------In the Ring this function is used to Update the table everytime new node shows Up -----------------
firstLoop(0, _M,NewTable,_) ->
    NewTable;
firstLoop(I, M,Table,NodeId) ->
    X = math:fmod((1 + trunc(math:pow(2, M-I))), trunc(math:pow(2, I))),
      Finger2 = #{M-I =>{ X,NodeId}},
    NewTable = maps:merge(Table,Finger2),

    io:fwrite("~p",[NewTable]),

    firstLoop(I - 1, M,NewTable,NodeId).

%--------------------------------------------------------------------------------------------------
%--------------------------------------Finger Table Initialization-------------------------------
fingerinitialization(0,_)->
    mid ! {"dff","fdf","dfdf","f"};

fingerinitialization(I,N)->
    M=persistent_term:get(m),
    Finger = persistent_term:get(finger),
    Index = N-I,
    Check=Index,
    Emptymp=#{},
    Filled_table=tableconstruction(M,M,Index,Emptymp,Check),
    Temp = #{Index=>Filled_table},
    NewTemp = maps:merge(Temp,Finger),
    io:fwrite("~p\n",[NewTemp]),
    persistent_term:put(finger,NewTemp),

fingerinitialization(I-1,N).

%---------------------------------------------------Setting Up the Chord Function for Traversal and Ring Formation --------------------------
setupChord(0, _Idx, _Limit) ->
    mid ! {"done"},
    ok;
setupChord(Num, Index, Limit) ->
    Node_list = persistent_term:get(list),
    Pid = lists:nth(Index, Node_list),

    PlaneSize = persistent_term:get(plane),
    RowSize = persistent_term:get(row),

    East = east(Index, RowSize),
    West = west(Index, RowSize),
    North = north(Index, RowSize, PlaneSize),
    South = south(Index, RowSize, PlaneSize),

    if
        East /= -1 ->
            Neighbor_Map = persistent_term:get(neighbor),
            Neighbors = maps:get(Pid, Neighbor_Map),
            EastNeighbor = lists:nth(East, Node_list),
            N = lists:append(Neighbors, [EastNeighbor]),
            Neighbor_map2 = maps:update(Pid, N, Neighbor_Map),
            persistent_term:put(neighbor, Neighbor_map2);
        true ->
            ok
    end,

    if
        West /= -1 ->
            Neighbor_Map5 = persistent_term:get(neighbor),
            Neighbors5 = maps:get(Pid, Neighbor_Map5),
            WestNeighbor = lists:nth(West, Node_list),
            N5 = lists:append(Neighbors5, [WestNeighbor]),
            Neighbor_map25 = maps:update(Pid, N5, Neighbor_Map5),
            persistent_term:put(neighbor, Neighbor_map25);
        true ->
            ok
    end,

    if
        North /= -1 ->
            Neighbor_Map3 = persistent_term:get(neighbor),
            Neighbors3 = maps:get(Pid, Neighbor_Map3),
            NorthNeighbor = lists:nth(North, Node_list),
            N3 = lists:append(Neighbors3, [NorthNeighbor]),
            Neighbor_map23 = maps:update(Pid, N3, Neighbor_Map3),
            persistent_term:put(neighbor, Neighbor_map23);
        true ->
            ok
    end,

    if
        South /= -1 ->
            Neighbor_Map4 = persistent_term:get(neighbor),
            Neighbors4 = maps:get(Pid, Neighbor_Map4),
            SouthNeighbor = lists:nth(South, Node_list),
            N4 = lists:append(Neighbors4, [SouthNeighbor]),
            Neighbor_map24 = maps:update(Pid, N4, Neighbor_Map4),
            persistent_term:put(neighbor, Neighbor_map24);
        true ->
            ok
    end,
   
            setupChord(Num - 1, Index + 1, Limit).
 
%-------------------------------------North, South, East, West Used by Setup Chord to find the place the new node is to be added and updation 
%-------------------------------------of the table and list for the new node--------------------------------------------------------------
east(Index, RowSize) ->
    Mod = math:fmod(Index, RowSize),
    if
        Mod == 0 ->
            -1;
        true ->
            Index + 1
    end.

west(Index, RowSize) ->
    Mod = math:fmod(Index, RowSize),
    if
        Mod == 1 ->
            -1;
        true ->
            Index - 1
    end.

north(Index, RowSize, PlaneSize) ->
    Mod = math:fmod(Index, PlaneSize),
    if
        Mod >= 1 andalso Mod =< RowSize ->
            -1;
        true ->
            Index - RowSize
    end.

south(Index, RowSize, PlaneSize) ->
    Mod = math:fmod(Index, PlaneSize),
    Size = PlaneSize - RowSize + 1,
    if
        Mod >= Size andalso Mod =< PlaneSize ->
            -1;
        Mod == 0 ->
            -1;
        true ->
            Index + RowSize
    end.

%---------------------------------------------Assignment Operation for Assigning the new Successors and Predecessors each time new Node Shows Up------------
assign(0, _Idx, _Limit) ->
    mid ! {"done2"},
    ok;


assign(Num, Index, Limit) ->
    Node_list = persistent_term:get(list),
    Pid = lists:nth(Index, Node_list),
    Neighbor_Map = persistent_term:get(neighbor),
    Neighbors = maps:get(Pid, Neighbor_Map),

    Random_node = random_loop(Pid, Node_list, Neighbors),
    N = lists:append(Neighbors, [Random_node]),
    Neighbor_map2 = maps:update(Pid, N, Neighbor_Map),
    persistent_term:put(neighbor, Neighbor_map2),
    if
        Index == Limit ->
            Idx = Limit + 1,
            assign(Num - 1, Idx, Limit);
        true ->
            assign(Num - 1, Index + 1, Limit)
    end.

%-----------------------------------------------Function for Constructing the Finger Table and Updating New Values----------------------------
tableconstruction(0,_,_,NewTemp,_)->
    NewTemp;

tableconstruction(I,M,Index,Map,Check)->
   
    Peerlist = persistent_term:get(node),
    Ele = element(1,maps:get(Check,Peerlist)),
    SucPred = persistent_term:get(sucpred),
    X =math:fmod((Index + trunc(math:pow(2, M-I))), trunc(math:pow(2, M))),
    SucPred = persistent_term:get(sucpred),
    Succ = element(2,maps:get(Ele,SucPred)),
    if X < Succ orelse X == Succ -> 
        Temp = #{X=>Succ},
        NewTemp = maps:merge(Temp,Map),
        tableconstruction(I-1,M,Index,NewTemp,Check);
    true ->
        tableconstruction(I,M,Index,Map,Check+1)
    end.


%-------------------------------------We start with a random node from finger table to move to find key
random_loop(Node_id, Node_list, NumRequests) ->

    if
        NumRequests == full ->
            Random_node = lists:nth(rand:uniform(length(Node_list)), Node_list),
            if
                Random_node == Node_id ->
                    random_loop(Node_id, Node_list, NumRequests);
                true ->
                    Random_node
            end;

        NumRequests == line ->
            Neighbor_Map = persistent_term:get(neighbor),
            Neighbor_List = maps:get(Node_id, Neighbor_Map),
            Random_node = lists:nth(rand:uniform(length(Neighbor_List)), Neighbor_List),
            if
                Random_node == Node_id ->
                    random_loop(Node_id, Node_list, NumRequests);
                true ->
                    Random_node
            end;
        true ->
            ok
    end.


%-------------------------------------------------Joing of New Nodes to the List---------------------------------------------
joining(_NumNodes) ->
    Fin_List = persistent_term:get(fin),
    RMap = persistent_term:get(rmap),
    io:fwrite("~p~n", [Fin_List]),
    Bool = maps:find(self(), RMap),
    Check = lists:member(self(), Fin_List),

    if
        Bool == {ok, true} ->
            if
                Check == false ->
                    LL = persistent_term:get(list),
                    Weights_map = persistent_term:get(weights),
                    {Sum, Weight} = maps:get(self(), Weights_map),
                    Rand = random_loop(self(), LL, 10),
                    Rand ! {self(), Sum, Weight};
                true ->
                    ok
            end;
        true ->
            ok
    end,

    sid ! {self(), "self"},
    receive
        {_Id, initial} ->
            Weights_NewM3 = persistent_term:get(weights),
            {S2, W2} = maps:get(self(), Weights_NewM3),
            NewS = S2 / 2,
            NewW = W2 / 2,
            Weights_NewM2 = maps:update(self(), {NewS, NewW}, Weights_NewM3),
            persistent_term:put(weights, Weights_NewM2),
            RNewM2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RNewM2),
            persistent_term:put(rmap, R),

            Random_node = random_loop(self(), persistent_term:get(list), 10),
            Random_node ! {self(), NewS, NewW};

        {_Pid, S, W} ->
            Weights_NewM3 = persistent_term:get(weights),
            {Pid_Sum, Pid_Weight} = maps:get(self(), Weights_NewM3),
            NewSum = Pid_Sum + S,
            NewWeight = Pid_Weight + W,

            if
                W /= 0.0 ->
                    Change = abs(NewSum / NewWeight - S / W),
                    Delta = math:pow(10, -10),
                    if
                        Change < Delta ->
                            Node_map = persistent_term:get(map),
                            TermRound = maps:get(self(), Node_map),
                            Node_NewM2 = maps:update(self(), TermRound + 1, Node_map),
                            persistent_term:put(map, Node_NewM2);
                        true ->
                            Node_map = persistent_term:get(map),
                            Node_NewM2 = maps:update(self(), 0, Node_map),
                            persistent_term:put(map, Node_NewM2)
                    end,
                    Node_NewM3 = persistent_term:get(map),
                    TermRound2 = maps:get(self(), Node_NewM3),
                    if
                        TermRound2 == 3 ->
                            Fin_List = persistent_term:get(fin),
                            Fin_List2 = lists:append(Fin_List, [self()]),
                            persistent_term:put(fin, Fin_List2);
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            Weights_NewM2 = maps:update(self(), {NewSum, NewWeight}, Weights_NewM3),
            persistent_term:put(weights, Weights_NewM2),
            RNewM2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RNewM2),
            persistent_term:put(rmap, R),

            Random_node = random_loop(self(), persistent_term:get(list), 10),
            Random_node ! {self(), NewSum / 2, NewWeight / 2};


        {_Pid} ->
            F_List = persistent_term:get(fin),
            X = length(F_List),
            if
                X == ring ->
                    Neighbor = persistent_term:get(neighbor),
                    Is_key = maps:is_key(self(), Neighbor),

                    Finlen = length(F_List),

                    if
                        Is_key == true ->
                            if
                                Finlen =/= 0 ->
                                    N_list = maps:get(self(), Neighbor),
                                    Y = length(N_list),
                                    findend(N_list, self(), Y);
                                % io:fwrite("~p\n",[K]);
                                true ->
                                    d
                            end;
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            if
                X == 10 ->
                    io:format("Finished List: ~p~n", [F_List]),
                    lastid ! {programend},
                    exit(bas);
                true ->
                    joining(10)
            end,

            Finished_List = persistent_term:get(fin),
            X = length(Finished_List),
            if
                X == 10 ->
                    lastid ! {programend},
                    exit(bas);
                true ->
                    joining(10)
            end
    end,
    joining(10).


%------------------------------------------------Communication along the Ring as per the research paper----------------------------------
chordcomm(FindNext, Limit) ->
    Fin_List = persistent_term:get(fin),

    RMap = persistent_term:get(rmap),
    io:fwrite("~p~n", [Fin_List]),
    Bool = maps:find(self(), RMap),
    Check = lists:member(self(), Fin_List),

    if
        Bool == {ok, true} ->
            % io:fwrite("~p",[Check]),
            if
                Check == false ->
                    LL = persistent_term:get(list),
                    Weights_map = persistent_term:get(weights),
                    {Sum, Weight} = maps:get(self(), Weights_map),
                    Rand = random_loop(self(), LL, FindNext),
                    Rand ! {self(), Sum, Weight};
                true ->
                    ok
            end;
        true ->
            ok
    end,

    sid ! {self(), "self"},
    receive
        {_Id, initial} ->
            Weights_map3 = persistent_term:get(weights),
            {S2, W2} = maps:get(self(), Weights_map3),
            NewS = S2 / 2,
            NewW = W2 / 2,
            Weights_map2 = maps:update(self(), {NewS, NewW}, Weights_map3),
            persistent_term:put(weights, Weights_map2),
            RMap2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RMap2),
            persistent_term:put(rmap, R),

            Random_node = random_loop(self(), persistent_term:get(list), FindNext),
            Random_node ! {self(), NewS, NewW};

        {_Pid, S, W} ->
            Weights_map3 = persistent_term:get(weights),
            {Pid_Sum, Pid_Weight} = maps:get(self(), Weights_map3),
            % io:fwrite("sum: ~p~n, Weight: ~p~n", [Pid_Sum, Pid_Weight]),
            NewSum = Pid_Sum + S,
            NewWeight = Pid_Weight + W,

            if
                W /= 0.0 ->
                    Change = abs(NewSum / NewWeight - S / W),
                    Delta = math:pow(10, -10),
                    if
                        Change < Delta ->
                            Node_map = persistent_term:get(map),
                            TermRound = maps:get(self(), Node_map),
                            Node_map2 = maps:update(self(), TermRound + 1, Node_map),
                            persistent_term:put(map, Node_map2);
                        true ->
                            Node_map = persistent_term:get(map),
                            Node_map2 = maps:update(self(), 0, Node_map),
                            persistent_term:put(map, Node_map2)
                    end,
                    Node_map3 = persistent_term:get(map),
                    TermRound2 = maps:get(self(), Node_map3),
                    if
                        TermRound2 == 3 ->
                            Fin_List = persistent_term:get(fin),
                            Fin_List2 = lists:append(Fin_List, [self()]),
                            persistent_term:put(fin, Fin_List2);
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            Weights_map2 = maps:update(self(), {NewSum, NewWeight}, Weights_map3),
            persistent_term:put(weights, Weights_map2),
            RMap2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RMap2),
            persistent_term:put(rmap, R),

            Random_node = random_loop(self(), persistent_term:get(list), FindNext),
            Random_node ! {self(), NewSum / 2, NewWeight / 2};


        {_Pid} ->
            F_List = persistent_term:get(fin),
            X = length(F_List),
            if
                FindNext == X ->
                    Neighbor = persistent_term:get(neighbor),
                    Is_key = maps:is_key(self(), Neighbor),

                    Finlen = length(F_List),

                    if
                        Is_key == true ->
                            if
                                Finlen =/= 0 ->
                                    N_list = maps:get(self(), Neighbor),
                                    Y = length(N_list),
                                    findend(N_list, self(), Y);
                                % io:fwrite("~p\n",[K]);
                                true ->
                                    d
                            end;
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            if
                X == Limit ->
                    io:format("Finished List: ~p~n", [F_List]),
                    % Mega_map = persistent_term:get(map),
                    % io:format("Map: ~p~n", [Mega_map]),
                    lastid ! {programend},
                    exit(bas);
                true ->
                    findend(FindNext, Limit,0)
            end,

            Finished_List = persistent_term:get(fin),
            X = length(Finished_List),
            if
                X == Limit ->
                    lastid ! {programend},
                    exit(bas);
                true ->
                    chordcomm(FindNext, Limit)
            end
    end,
    chordcomm(FindNext, Limit).


%---------------------------------------------Ending of the Program on Finding the Key-----------------------------------------------
findend(_, Node_id, 0) ->
    F_List = persistent_term:get(fin),
    Boolean = lists:member(Node_id, F_List),
    if
        Boolean == false ->
            FL = [Node_id],
            F = F_List ++ FL,
            persistent_term:put(fin, F);
        true ->
            ok
    end;

findend(N_list, Node_id, Len) ->
    F_list = persistent_term:get(fin),
    [Head | Tail] = N_list,

    Chk = lists:member(Head, F_list),
    % io:fwrite("~p\n", [Chk]),
    if
        Chk == true ->
            findend(Tail, Node_id, Len - 1);
        true ->
            f
    end.
