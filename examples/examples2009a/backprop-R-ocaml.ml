let sum_activities activities (bias::ws) =
  fold_left ( +. ) bias (map2 ( *. ) ws activities)

let sum_layer activities ws_layer = map (sum_activities activities) ws_layer

let sigmoid x = (Base 1.0)/.((exp ((Base 0.0)-.x))+.(Base 1.0))

let rec forward_pass a in1 =
  match a with
    []  -> in1
  | (ws_layer::ws_layers) ->
      forward_pass ws_layers (map sigmoid (sum_layer in1 ws_layer))

let error_on_dataset dataset ws_layers =
  fold_left ( +. )
    (Base 0.0)
    (map (fun (in1, target) ->
      (Base 0.5)*.
	(magnitude_squared
	   (vminus (forward_pass ws_layers in1) target)))
       dataset)

let s_kstar ws k y =
  map2 (fun l y ->
    map2 (fun u y -> map2 (fun w y -> w-.k*.y) u y) l y)
    ws y

let weight_gradient f ws =
  (epsilon := !epsilon+.(Base 1.0);
   let ws = map (fun l ->
     map (fun u ->
       map (fun w -> (tape (!epsilon) w [] [])) u) l)
       ws
   in (match f ws with
     Dual_number _ -> ()
   | Tape (e1, _, _, _, _, _) as y->
       if e1<(!epsilon)
       then ()
       else (determine_fanout y; reverse_phase (Base 1.0) y)
   | Base _ -> ());
   epsilon := !epsilon-.(Base 1.0);
   map (fun l ->
     map (fun u ->
       map (fun (Tape (_, _, _, _, _, sensitivity)) -> !sensitivity) u)
       l)
     ws)

let rec vanilla f w0 n eta =
  if n<=(Base 0.0) && (Base 0.0)<=n
  then f w0
  else vanilla f (s_kstar w0 eta (weight_gradient f w0)) (n-.(Base 1.0)) eta

let xor_ws0 = [[[Base 0.0; Base (-0.284227); Base 1.16054];
		[Base 0.0; Base  0.617194; Base 1.30467]];
	       [[Base 0.0; Base (-0.084395); Base 0.648461]]]

let xor_data = [([Base 0.0; Base 0.0], [Base 0.0]);
		([Base 0.0; Base 1.0], [Base 1.0]);
		([Base 1.0; Base 0.0], [Base 1.0]);
		([Base 1.0; Base 1.0], [Base 0.0])]

let _ = write_real (vanilla (error_on_dataset xor_data)
		      xor_ws0
		      (Base 1000000.0)
		      (Base 0.3)); 0
