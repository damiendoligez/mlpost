open Point
open Command
open Dash
module SP = Path

let fig = 
  [draw ~dashed:(scaled 2. evenly) (SP.path ~scale:Num.cm [0.,0.; 3.,0.]) ;
   draw ~dashed:evenly (SP.path ~scale:Num.mm [0.,-5.; 30.,-5.]) ]
