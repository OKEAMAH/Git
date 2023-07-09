(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(* Testing
   -------
   Component:    Lib Bls12_381_hash
   Invocation:   dune exec src/lib_bls12_381_hash/test/main.exe \
                  -- --file test_anemoi.ml
   Subject:      Test Bls12_381_hash
*)

(* Generated using
   https://github.com/vesselinux/anemoi-hash/commit/9d9fc2a52e31c5e9379be2856414233e4e780f58
   with:
       test_jive(
           n_tests=10,
           q=52435875175126190479447740508185965837690552500527637822603658699938581184513,
           alpha=5,
           n_rounds=19,
           n_cols=1,
           b=2,
           security_level=128)
*)

let test_vectors_anemoi128_1 () =
  let vectors =
    [
      ( ("0", "0"),
        "20387392009611881691526522206552322482509551426930619434849280967122120965518"
      );
      ( ("1", "1"),
        "44271465307610833975255894848424514129463332778307888463652844119174793376849"
      );
      ( ("0", "1"),
        "48081255911378449855577187903249438549252129278233190684459831383162273301317"
      );
      ( ("1", "0"),
        "20987090084610650936759092866102729962368129813397495848982616983114798496095"
      );
      ( ( "28833081522569191485031800007200531958068979190210245290304092559054270519757",
          "45627636979028602700169119083772012394045194561275706149573846946517729876940"
        ),
        "37226954706656919870784319878469984156264276283273792021144953697211586641218"
      );
      ( ( "2691314882484839960674590644999236122022886574013148396040045419088338604640",
          "18143668977361221201906822233833819246768728507688785886696446874566677815865"
        ),
        "13960957389479770735707733244643525086546785716979595781545128710107394816400"
      );
      ( ( "34207353498441999460045415828405148537232198397858656730183294382158169831294",
          "28704411036278677998016252512308859888020038794909096443317182350359270741277"
        ),
        "16293660492305303582892142758855821722168348553969129728182704079139408447061"
      );
    ]
  in
  List.iter
    (fun ((x1_s, x2_s), exp_res_s) ->
      let x1 = Bls12_381.Fr.of_string x1_s in
      let x2 = Bls12_381.Fr.of_string x2_s in
      let exp_res = Bls12_381.Fr.of_string exp_res_s in
      let res = Bls12_381_hash.Permutation.Anemoi.jive128_1 x1 x2 in
      if not (Bls12_381.Fr.eq res exp_res) then
        Alcotest.failf
          "Expected result = %s, computed result = %s, input = (%s, %s)"
          exp_res_s
          (Bls12_381.Fr.to_string res)
          x1_s
          x2_s)
    vectors

let test_vectors_anemoi128_2 () =
  let vectors =
    [
      ( ("0", "0", "0", "0"),
        ( "50373488281886067231742822955993981574671556522938395357859238673272835062006",
          "37649133660709062470883016050302328693947964454407709511898849179550062364491",
          "50198748742393366985878240532628292457659945083860507484685404605945263477087",
          "12168196333990471181410244399119814959611137367419072139683054342502871297656"
        ) );
    ]
  in

  List.iter
    (fun ( (x1_s, x2_s, y1_s, y2_s),
           (exp_res_x1_s, exp_res_x2_s, exp_res_y1_s, exp_res_y2_s) ) ->
      let x1 = Bls12_381.Fr.of_string x1_s in
      let x2 = Bls12_381.Fr.of_string x2_s in
      let y1 = Bls12_381.Fr.of_string y1_s in
      let y2 = Bls12_381.Fr.of_string y2_s in
      let exp_res_x1 = Bls12_381.Fr.of_string exp_res_x1_s in
      let exp_res_x2 = Bls12_381.Fr.of_string exp_res_x2_s in
      let exp_res_y1 = Bls12_381.Fr.of_string exp_res_y1_s in
      let exp_res_y2 = Bls12_381.Fr.of_string exp_res_y2_s in
      let state = [|x1; x2; y1; y2|] in
      let ctxt =
        Bls12_381_hash.Permutation.Anemoi.allocate_ctxt
          Bls12_381_hash.Permutation.Anemoi.Parameters.security_128_state_size_4
      in
      let () = Bls12_381_hash.Permutation.Anemoi.set_state ctxt state in
      let () = Bls12_381_hash.Permutation.Anemoi.apply_permutation ctxt in
      let output = Bls12_381_hash.Permutation.Anemoi.get_state ctxt in
      let res_x1, res_x2, res_y1, res_y2 =
        (output.(0), output.(1), output.(2), output.(3))
      in
      let res_x1_s = Bls12_381.Fr.to_string res_x1 in
      let res_x2_s = Bls12_381.Fr.to_string res_x2 in
      let res_y1_s = Bls12_381.Fr.to_string res_y1 in
      let res_y2_s = Bls12_381.Fr.to_string res_y2 in
      let is_eq =
        Bls12_381.Fr.eq res_x1 exp_res_x1
        && Bls12_381.Fr.eq res_x2 exp_res_x2
        && Bls12_381.Fr.eq res_y1 exp_res_y1
        && Bls12_381.Fr.eq res_y2 exp_res_y2
      in
      if not is_eq then
        Alcotest.failf
          "Expected result = (%s, %s, %s, %s), computed result = (%s, %s, %s, \
           %s), input = (%s, %s, %s, %s)"
          exp_res_x1_s
          exp_res_x2_s
          exp_res_y1_s
          exp_res_y2_s
          res_x1_s
          res_x2_s
          res_y1_s
          res_y2_s
          x1_s
          x2_s
          y1_s
          y2_s)
    vectors

let test_vectors_anemoi128_3 () =
  let vectors =
    [
      ( ("0", "0", "0", "0", "0", "0"),
        ( "537262717341931034267396310739856793295247715945853897217694211756837724523",
          "6316161038428245337923977278352992491332565548294086783819587919180447065889",
          "23063783020380320657931795367183548623662516338488544612906079046319169120820",
          "47024895756273874704653756272535424177422682864381760912751063532020422440298",
          "26643869639782940533534638001181633565993548330838663374788552564670170581723",
          "51223440839408008640559200265692681090398626473992839760152971916451561715150"
        ) );
    ]
  in

  List.iter
    (fun ( (x1_s, x2_s, x3_s, y1_s, y2_s, y3_s),
           ( exp_res_x1_s,
             exp_res_x2_s,
             exp_res_x3_s,
             exp_res_y1_s,
             exp_res_y2_s,
             exp_res_y3_s ) ) ->
      let x1 = Bls12_381.Fr.of_string x1_s in
      let x2 = Bls12_381.Fr.of_string x2_s in
      let x3 = Bls12_381.Fr.of_string x3_s in
      let y1 = Bls12_381.Fr.of_string y1_s in
      let y2 = Bls12_381.Fr.of_string y2_s in
      let y3 = Bls12_381.Fr.of_string y3_s in
      let exp_res_x1 = Bls12_381.Fr.of_string exp_res_x1_s in
      let exp_res_x2 = Bls12_381.Fr.of_string exp_res_x2_s in
      let exp_res_x3 = Bls12_381.Fr.of_string exp_res_x3_s in
      let exp_res_y1 = Bls12_381.Fr.of_string exp_res_y1_s in
      let exp_res_y2 = Bls12_381.Fr.of_string exp_res_y2_s in
      let exp_res_y3 = Bls12_381.Fr.of_string exp_res_y3_s in
      let state = [|x1; x2; x3; y1; y2; y3|] in
      let ctxt =
        Bls12_381_hash.Permutation.Anemoi.allocate_ctxt
          Bls12_381_hash.Permutation.Anemoi.Parameters.security_128_state_size_6
      in
      let () = Bls12_381_hash.Permutation.Anemoi.set_state ctxt state in
      let () = Bls12_381_hash.Permutation.Anemoi.apply_permutation ctxt in
      let output = Bls12_381_hash.Permutation.Anemoi.get_state ctxt in
      let res_x1, res_x2, res_x3, res_y1, res_y2, res_y3 =
        (output.(0), output.(1), output.(2), output.(3), output.(4), output.(5))
      in
      let res_x1_s = Bls12_381.Fr.to_string res_x1 in
      let res_x2_s = Bls12_381.Fr.to_string res_x2 in
      let res_x3_s = Bls12_381.Fr.to_string res_x3 in
      let res_y1_s = Bls12_381.Fr.to_string res_y1 in
      let res_y2_s = Bls12_381.Fr.to_string res_y2 in
      let res_y3_s = Bls12_381.Fr.to_string res_y3 in
      let is_eq =
        Bls12_381.Fr.eq res_x1 exp_res_x1
        && Bls12_381.Fr.eq res_x2 exp_res_x2
        && Bls12_381.Fr.eq res_x3 exp_res_x3
        && Bls12_381.Fr.eq res_y1 exp_res_y1
        && Bls12_381.Fr.eq res_y2 exp_res_y2
        && Bls12_381.Fr.eq res_y3 exp_res_y3
      in
      if not is_eq then
        Alcotest.failf
          "Expected result = (%s, %s, %s, %s, %s, %s), computed result = (%s, \
           %s, %s, %s, %s, %s), input = (%s, %s, %s, %s, %s, %s)"
          exp_res_x1_s
          exp_res_x2_s
          exp_res_x3_s
          exp_res_y1_s
          exp_res_y2_s
          exp_res_y3_s
          res_x1_s
          res_x2_s
          res_x3_s
          res_y1_s
          res_y2_s
          res_y3_s
          x1_s
          x2_s
          x3_s
          y1_s
          y2_s
          y3_s)
    vectors

let test_vectors_anemoi128_4 () =
  let vectors =
    [
      ( ("0", "0", "0", "0", "0", "0", "0", "0"),
        ( "36355873859496768064889006231445823838007734572491025538355015718308557843666",
          "18069323727523259608218315697968600475965284186717101024337316534317381566109",
          "4781781034094329945250091989810634079767277631982799931785605928387349221520",
          "33657114511787724194084375331316897067429695676979350605727307010580643746108",
          "34423276393245967983603861340180189628053396422848474142450132085162105282053",
          "30330281041957824360873451824730706647923620048523720035979941519403506789561",
          "292424825113749593137169592959345767701701957936920002046886769695791987731",
          "41846727893865299198987526031930460509610742862729515571859891458689040353460"
        ) );
    ]
  in

  List.iter
    (fun ( (x1_s, x2_s, x3_s, x4_s, y1_s, y2_s, y3_s, y4_s),
           ( exp_res_x1_s,
             exp_res_x2_s,
             exp_res_x3_s,
             exp_res_x4_s,
             exp_res_y1_s,
             exp_res_y2_s,
             exp_res_y3_s,
             exp_res_y4_s ) ) ->
      let x1 = Bls12_381.Fr.of_string x1_s in
      let x2 = Bls12_381.Fr.of_string x2_s in
      let x3 = Bls12_381.Fr.of_string x3_s in
      let x4 = Bls12_381.Fr.of_string x4_s in
      let y1 = Bls12_381.Fr.of_string y1_s in
      let y2 = Bls12_381.Fr.of_string y2_s in
      let y3 = Bls12_381.Fr.of_string y3_s in
      let y4 = Bls12_381.Fr.of_string y4_s in
      let exp_res_x1 = Bls12_381.Fr.of_string exp_res_x1_s in
      let exp_res_x2 = Bls12_381.Fr.of_string exp_res_x2_s in
      let exp_res_x3 = Bls12_381.Fr.of_string exp_res_x3_s in
      let exp_res_x4 = Bls12_381.Fr.of_string exp_res_x4_s in
      let exp_res_y1 = Bls12_381.Fr.of_string exp_res_y1_s in
      let exp_res_y2 = Bls12_381.Fr.of_string exp_res_y2_s in
      let exp_res_y3 = Bls12_381.Fr.of_string exp_res_y3_s in
      let exp_res_y4 = Bls12_381.Fr.of_string exp_res_y4_s in
      let state = [|x1; x2; x3; x4; y1; y2; y3; y4|] in
      let ctxt =
        Bls12_381_hash.Permutation.Anemoi.(
          allocate_ctxt Parameters.security_128_state_size_8)
      in
      let () = Bls12_381_hash.Permutation.Anemoi.set_state ctxt state in
      let () = Bls12_381_hash.Permutation.Anemoi.apply_permutation ctxt in
      let output = Bls12_381_hash.Permutation.Anemoi.get_state ctxt in
      let res_x1, res_x2, res_x3, res_x4, res_y1, res_y2, res_y3, res_y4 =
        ( output.(0),
          output.(1),
          output.(2),
          output.(3),
          output.(4),
          output.(5),
          output.(6),
          output.(7) )
      in
      let res_x1_s = Bls12_381.Fr.to_string res_x1 in
      let res_x2_s = Bls12_381.Fr.to_string res_x2 in
      let res_x3_s = Bls12_381.Fr.to_string res_x3 in
      let res_x4_s = Bls12_381.Fr.to_string res_x4 in
      let res_y1_s = Bls12_381.Fr.to_string res_y1 in
      let res_y2_s = Bls12_381.Fr.to_string res_y2 in
      let res_y3_s = Bls12_381.Fr.to_string res_y3 in
      let res_y4_s = Bls12_381.Fr.to_string res_y4 in
      let is_eq =
        Bls12_381.Fr.eq res_x1 exp_res_x1
        && Bls12_381.Fr.eq res_x2 exp_res_x2
        && Bls12_381.Fr.eq res_x3 exp_res_x3
        && Bls12_381.Fr.eq res_x4 exp_res_x4
        && Bls12_381.Fr.eq res_y1 exp_res_y1
        && Bls12_381.Fr.eq res_y2 exp_res_y2
        && Bls12_381.Fr.eq res_y3 exp_res_y3
        && Bls12_381.Fr.eq res_y4 exp_res_y4
      in
      if not is_eq then
        Alcotest.failf
          "Expected result = (%s, %s, %s, %s, %s, %s, %s, %s), computed result \
           = (%s, %s, %s, %s, %s, %s, %s, %s), input = (%s, %s, %s, %s, %s, \
           %s, %s, %s)"
          exp_res_x1_s
          exp_res_x2_s
          exp_res_x3_s
          exp_res_x4_s
          exp_res_y1_s
          exp_res_y2_s
          exp_res_y3_s
          exp_res_y4_s
          res_x1_s
          res_x2_s
          res_x3_s
          res_x4_s
          res_y1_s
          res_y2_s
          res_y3_s
          res_y4_s
          x1_s
          x2_s
          x3_s
          x4_s
          y1_s
          y2_s
          y3_s
          y4_s)
    vectors

let test_state_functions () =
  let l = 5 + Random.int 10 in
  let mds =
    Array.init l (fun _ -> Array.init l (fun _ -> Bls12_381.Fr.random ()))
  in
  let state_size = 2 * l in
  let state = Array.init state_size (fun _ -> Bls12_381.Fr.random ()) in
  let parameters =
    (Bls12_381_hash.Permutation.Anemoi.Parameters.create
       128
       state_size
       mds [@warning "-3"])
  in
  let ctxt = Bls12_381_hash.Permutation.Anemoi.allocate_ctxt parameters in
  let () = Bls12_381_hash.Permutation.Anemoi.set_state ctxt state in
  let output = Bls12_381_hash.Permutation.Anemoi.get_state ctxt in
  if not (Array.for_all2 Bls12_381.Fr.eq state output) then
    Alcotest.failf
      "Exp: [%s], computed: [%s]"
      (String.concat
         "; "
         (List.map Bls12_381.Fr.to_string (Array.to_list state)))
      (String.concat
         "; "
         (List.map Bls12_381.Fr.to_string (Array.to_list output)))

let test_anemoi_generic_with_l_one_is_anemoi_jive128_1 () =
  let state_size = 2 in
  let state = Array.init state_size (fun _ -> Bls12_381.Fr.random ()) in
  let ctxt =
    Bls12_381_hash.Permutation.Anemoi.(
      allocate_ctxt Parameters.security_128_state_size_2)
  in
  let () = Bls12_381_hash.Permutation.Anemoi.set_state ctxt state in
  let () = Bls12_381_hash.Permutation.Anemoi.apply_permutation ctxt in
  let output = Bls12_381_hash.Permutation.Anemoi.get_state ctxt in
  assert (
    Bls12_381.Fr.eq
      (Bls12_381_hash.Permutation.Anemoi.jive128_1 state.(0) state.(1))
      Bls12_381.Fr.(state.(0) + state.(1) + output.(0) + output.(1)))

let test_compute_number_of_rounds () =
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 2 128
    = 21) ;
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 4 128
    = 14) ;
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 6 128
    = 12) ;
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 8 128
    = 12) ;
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 2 256
    = 37) ;
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 4 256
    = 22) ;
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 6 256
    = 17) ;
  assert (
    Bls12_381_hash.Permutation.Anemoi.Parameters.compute_number_of_rounds 8 256
    = 16)

let test_anemoi_generate_constants () =
  let l = 1 in
  let nb_rounds = 19 in
  let exp_res =
    Bls12_381.Fr.
      [|
        of_string "39";
        of_string
          "41362478282768062297187132445775312675360473883834860695283235286481594490621";
        of_string
          "9548818195234740988996233204400874453525674173109474205108603996010297049928";
        of_string
          "25365440569177822667580105183435418073995888230868180942004497015015045856900";
        of_string
          "34023498397393406644117994167986720327178154686105264833093891093045919619309";
        of_string
          "38816051319719761886041858113129205506758421478656182868737326994635468402951";
        of_string
          "35167418087531820804128377095512663922179887277669504047069913414630376083753";
        of_string
          "25885868839756469722325652387535232478219821850603640827385444642154834700231";
        of_string
          "8867588811641202981080659274007552529205713737251862066053445622305818871963";
        of_string
          "36439756010140137556111047750162544185710881404522379792044818039722752946048";
        of_string
          "7788624504122357216765350546787885309160020166693449889975992574536033007374";
        of_string
          "3134147137704626983201116226440762775442116005053282329971088789984415999550";
        of_string
          "50252287380741824818995733304361249016282047978221591906573165442023106203143";
        of_string
          "48434698978712278012409706205559577163572452744833134361195687109159129985373";
        of_string
          "32960510617530186159512413633821386297955642598241661044178889571655571939473";
        of_string
          "12850897859166761094422335671106280470381427571695744605265713866647560628356";
        of_string
          "14578036872634298798382048587794204613583128573535557156943783762854124345644";
        of_string
          "21588109842058901916690548710649523388049643745013696896704903154857389904594";
        of_string
          "35731638686520516424752846654442973203189295883541072759390882351699754104989";
        of_string
          "14981678621464625851270783002338847382197300714436467949315331057125308909900";
        of_string
          "28253420209785428420233456008091632509255652343634529984400816700490470131093";
        of_string
          "51511939407083344002778208487678590135577660247075600880835916725469990319313";
        of_string
          "46291121544435738125248657675097664742296276807186696922340332893747842754587";
        of_string
          "3650460179273129580093806058710273018999560093475503119057680216309578390988";
        of_string
          "45802223370746268123059159806400152299867771061127345631244786118574025749328";
        of_string
          "11798621276624967315721748990709309216351696098813162382053396097866233042733";
        of_string
          "42372918959432199162670834641599336326433006968669415662488070504036922966492";
        of_string
          "52181371244193189669553521955614617990714056725501643636576377752669773323445";
        of_string
          "23791984554824031672195249524658580601428376029501889159059009332107176394097";
        of_string
          "33342520831620303764059548442834699069640109058400548818586964467754352720368";
        of_string
          "16791548253207744974576845515705461794133799104808996134617754018912057476556";
        of_string
          "11087343419860825311828133337767238110556416596687749174422888171911517001265";
        of_string
          "11931207770538477937808955037363240956790374856666237106403111503668796872571";
        of_string
          "3296943608590459582451043049934874894049468383833500962645016062634514172805";
        of_string
          "7080580976521357573320018355401935489220216583936865937104131954142364033647";
        of_string
          "25990144965911478244481527888046366474489820502460615136523859419965697796405";
        of_string
          "33907313384235729375566529911940467295099705980234607934575786561097199483218";
        of_string
          "25996950265608465541351207283024962044374873682152889814392533334239395044136";
      |]
  in
  let res =
    Bls12_381_hash.Permutation.Anemoi.Parameters.generate_constants nb_rounds l
  in
  assert (Array.for_all2 Bls12_381.Fr.eq exp_res res)

let () =
  let open Alcotest in
  run
    ~__FILE__
    "The permutation Anemoi and the mode of operation Jive"
    [
      ( "From reference implementation",
        [
          test_case
            "Tests vectors from reference implementation"
            `Quick
            test_vectors_anemoi128_1;
        ] );
      ( "Generic instantiations",
        [
          test_case
            "l = 1 <==> jive128_1"
            `Quick
            test_anemoi_generic_with_l_one_is_anemoi_jive128_1;
          test_case
            "l = 2 -> tests vectors from reference implementation"
            `Quick
            test_vectors_anemoi128_2;
          test_case
            "l = 3 -> tests vectors from reference implementation"
            `Quick
            test_vectors_anemoi128_3;
          test_case
            "l = 4 -> tests vectors from reference implementation"
            `Quick
            test_vectors_anemoi128_4;
        ] );
      ( "Additional functions",
        [
          test_case
            "State initialisation and get state"
            `Quick
            test_state_functions;
          test_case "Constant generation" `Quick test_anemoi_generate_constants;
          test_case
            "Compute number of rounds"
            `Quick
            test_compute_number_of_rounds;
        ] );
    ]
