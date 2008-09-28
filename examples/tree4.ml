open Box
open Tree

let fig =
  let node s = node (tex s) in
  let leaf s = leaf (tex s) in
  [draw ~arrow_style:Undirected ~edge_style:Square
     (node "1" [node "2" [leaf "4"; leaf "5"]; 
		node "3" [leaf "6"; leaf "7"]])]

