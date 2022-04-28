module Fr = Bls12_381.Fr
module Fr_generation = Polynomial__Fr_generation.Make (Fr)
module Poly = Polynomial.Univariate.Make (Fr)
module Domain = Polynomial__Domain.Domain_unsafe
module Poly_c = Polynomial__Polynomial_c.Polynomial_impl

let p_of_c : Poly_c.t -> Poly.t =
 fun poly -> Poly_c.to_sparse_coefficients poly |> Poly.of_coefficients

let test_build_domain () =
  let module Domain = Polynomial__Domain.Domain_impl in
  let log = 12 in
  let root_of_unity = Fr_generation.root_of_unity log in
  let domain_c = Domain.create log root_of_unity in
  let expected_domain = Fr_generation.build_domain log in
  let domain = Domain.to_array domain_c in
  assert (Array.for_all2 Fr.eq expected_domain domain)

let test_copy_polynomial () =
  let poly = Poly_c.generate_random_polynomial (Random.int 100) in
  assert (Poly_c.equal poly (Poly_c.copy poly))

let test_get_zero () =
  let p = Poly_c.zero in
  assert (Fr.(Poly_c.get p 0 = zero)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p (-1)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p 1)

let test_get_one () =
  let p = Poly_c.one in
  assert (Fr.(Poly_c.get p 0 = one)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p (-1)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p 1)

let test_get_random () =
  let module Poly_c = Polynomial__Polynomial_c.Polynomial_impl in
  let module C_array = Polynomial__Carray in
  let degree = 1 + Random.int 100 in
  let p = Poly_c.of_coefficients [(Fr.one, degree)] in
  assert (C_array.length p = degree + 1) ;
  Helpers.repeat 10 (fun () ->
      assert (Fr.eq (Poly_c.get p (Random.int (C_array.length p - 1))) Fr.zero)) ;
  Helpers.(
    repeat 10 (fun () ->
        let i = Random.int 10 in
        must_fail (fun () -> ignore @@ Poly_c.get p (-i - 1)) ;
        must_fail (fun () -> ignore @@ Poly_c.get p (C_array.length p + i))))

let test_one () =
  let p = Poly_c.one in
  let expected = Poly.one in
  assert (Poly.equal (p_of_c p) expected)

let test_degree () =
  let p1 = Poly_c.generate_random_polynomial (Random.int 100) in
  assert (Poly_c.degree p1 = Poly.degree_int (p_of_c p1))

let test_add () =
  let p1 = Poly_c.generate_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_random_polynomial (Random.int 100) in
  let res = Poly_c.add p1 p2 in
  let expected_res = Poly.add (p_of_c p1) (p_of_c p2) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_add_inplace () =
  let p1 = Poly_c.generate_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_random_polynomial (Random.int 100) in
  let expected_res = Poly.add (p_of_c p1) (p_of_c p2) in
  let res = Poly_c.add_inplace p1 p2 in
  assert (Poly.equal (p_of_c res) expected_res)

let test_sub () =
  let p1 = Poly_c.generate_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_random_polynomial (Random.int 100) in
  let res = Poly_c.sub p1 p2 in
  let expected_res = Poly.sub (p_of_c p1) (p_of_c p2) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_sub_inplace () =
  let p1 = Poly_c.generate_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_random_polynomial (Random.int 100) in
  let expected_res = Poly.sub (p_of_c p1) (p_of_c p2) in
  let res = Poly_c.sub_inplace p1 p2 in
  assert (Poly.equal (p_of_c res) expected_res)

let test_mul () =
  let p1 = Poly_c.generate_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_random_polynomial (Random.int 100) in
  let res = Poly_c.mul p1 p2 in
  let expected_res = Poly.polynomial_multiplication (p_of_c p1) (p_of_c p2) in
  assert (Poly.equal (p_of_c res) expected_res) ;
  let dres = Poly_c.degree res in
  let d1 = Poly_c.degree p1 in
  let d2 = Poly_c.degree p2 in
  if d1 = -1 || d2 = -1 then assert (dres = -1) else assert (dres = d1 + d2)

let test_opposite () =
  let p = Poly_c.generate_random_polynomial (Random.int 100) in
  let res = Poly_c.opposite p in
  let expected_res = Poly.opposite (p_of_c p) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_opposite_inplace () =
  let p = Poly_c.generate_random_polynomial (Random.int 100) in
  let expected_res = Poly.opposite (p_of_c p) in
  Poly_c.opposite_inplace p ;
  assert (Poly.equal (p_of_c p) expected_res)

let test_mul_by_scalar () =
  let p = Poly_c.generate_random_polynomial 100 in
  let s = Fr.random () in
  let res = Poly_c.mul_by_scalar s p in
  let expected_res = Poly.mult_by_scalar s (p_of_c p) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_mul_by_scalar_inplace () =
  let p = Poly_c.generate_random_polynomial 100 in
  let s = Fr.random () in
  let expected_res = Poly.mult_by_scalar s (p_of_c p) in
  Poly_c.mul_by_scalar_inplace s p ;
  assert (Poly.equal (p_of_c p) expected_res)

let test_is_zero () =
  let size = Random.int 100 in
  let poly_zero =
    Poly_c.of_coefficients (List.init size (fun i -> (Fr.copy Fr.zero, i)))
  in
  assert (Poly_c.is_zero poly_zero)

let test_evaluate () =
  let p = Poly_c.generate_random_polynomial 10 in
  let s = Fr.random () in
  let expected_res = Poly.evaluation (p_of_c p) s in
  let res = Poly_c.evaluate p s in
  assert (Fr.eq res expected_res)

let test_division_x_z () =
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_random_polynomial 100 in
      if Poly_c.degree p > 0 then p else generate ()
    in
    generate ()
  in
  let z = Fr.random () in
  let poly_non_divisible_caml = p_of_c poly_non_divisible in
  let poly_divisible_caml =
    Poly.(
      poly_non_divisible_caml * of_coefficients [(Fr.one, 1); (Fr.negate z, 0)])
  in

  let poly_divisible =
    Poly_c.of_coefficients (Poly.get_list_coefficients poly_divisible_caml)
  in
  let res = Poly_c.division_x_z poly_divisible z in
  let res_caml = p_of_c res in
  let (expected_quotient, expected_reminder) =
    Poly.euclidian_division_opt
      poly_divisible_caml
      (Poly.of_coefficients [(Fr.one, 1); (Fr.negate z, 0)])
    |> Option.get
  in
  assert (Poly.equal res_caml expected_quotient) ;
  assert (Poly.equal Poly.zero expected_reminder)

let test_division_zs () =
  let n = 10 in
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_random_polynomial 100 in
      if Polynomial__Carray.length p >= 2 * n then p else generate ()
    in
    generate ()
  in
  let poly_non_divisible_caml = p_of_c poly_non_divisible in
  let poly_divisible_caml =
    Poly.(
      poly_non_divisible_caml
      * of_coefficients [(Fr.one, n); (Fr.(negate one), 0)])
  in
  let poly_divisible =
    Poly_c.of_coefficients (Poly.get_list_coefficients poly_divisible_caml)
  in
  let res = Poly_c.division_zs poly_divisible n in
  let res_caml = p_of_c res in
  let (expected_quotient, expected_reminder) =
    Poly.euclidian_division_opt
      poly_divisible_caml
      (Poly.of_coefficients Fr.[(one, n); (negate one, 0)])
    |> Option.get
  in
  assert (Poly.equal res_caml expected_quotient) ;
  assert (Poly.equal Poly.zero expected_reminder)

let test_divsions_zs_limit_case () =
  (* We test the limit case in which the size of the polynomial is equal to 2*n
     ie. the degree is equal to 2*n. *)
  let n = 16 in
  let poly_non_divisible = Poly_c.of_coefficients [(Fr.random (), n - 1)] in
  let poly_non_divisible =
    Poly_c.add poly_non_divisible (Poly_c.generate_random_polynomial (n - 2))
  in
  let zs = Poly_c.(of_coefficients [(Fr.one, n); (Fr.(negate one), 0)]) in
  let poly_divisible = Poly_c.mul poly_non_divisible zs in
  assert (Poly_c.(mul_zs (division_zs poly_divisible n) n = poly_divisible)) ;
  assert (Poly_c.(mul (division_zs poly_divisible n) zs = poly_divisible))

let test_mul_zs () =
  let n = 50 in
  let p =
    let rec generate () =
      let d = n + Random.int 50 in
      let p = Poly_c.generate_random_polynomial d in
      if Poly_c.degree p >= n then p else generate ()
    in
    generate ()
  in
  let m = Poly_c.mul_zs p n in
  assert (Poly_c.(equal (division_zs m n) p))

let test_of_sparse_coefficients () =
  let test_vectors =
    [
      [|(Fr.random (), 0)|];
      (* FIXME: repr for zero polynomial *)
      (* [|(Fr.(copy zero), 0)|] *)
      [|(Fr.random (), 0); (Fr.(copy one), 1)|];
      Array.init (1 + Random.int 100) (fun i -> (Fr.random (), i));
      (* with zero coefficients somewhere *)
      [|(Fr.random (), 1)|];
      (let n = 1 + Random.int 100 in
       Array.init n (fun i -> (Fr.random (), (i * 100) + Random.int 100)));
      (* Not in order *)
      [|(Fr.random (), 1); (Fr.random (), 0)|];
      (* random polynomial where we shuffle randomly the coefficients *)
      (let n = 1 + Random.int 100 in
       let p =
         Array.init n (fun i -> (Fr.random (), (i * 100) + Random.int 100))
       in
       Array.fast_sort (fun _ _ -> if Random.bool () then 1 else -1) p ;
       p);
    ]
  in
  List.iter
    (fun coefficients ->
      let polynomial_c = Poly_c.of_coefficients (Array.to_list coefficients) in
      let polynomial = Poly_c.to_sparse_coefficients polynomial_c in
      Array.fast_sort (fun (_, i1) (_, i2) -> Int.compare i1 i2) coefficients ;
      List.iter2
        (fun (x1, i1) (x2, i2) ->
          if not (Fr.eq x1 x2 && i1 = i2) then
            Alcotest.failf
              "Expected output (%s, %d), computed (%s, %d)"
              (Fr.to_string x1)
              i1
              (Fr.to_string x2)
              i2)
        (Array.to_list coefficients)
        polynomial)
    test_vectors

let test_vectors_fft () =
  let vectors =
    [
      ( [|
          "27368034540955591518185075247638312229509481411752400387472688330662143761856";
          "19540886853600136773806888540031779652697522926951761090609474934921975120659";
          "26220624956959285725992525915931330099055855809419283071707941601749666540606";
          "35989465088288326521015971876164012326945860638993195438436634989311471699248";
          "40768987516446156628891831412618502769603720088125758542973088262778427031409";
          "37502582815775325591532709222383633732324588493894705918379415386493138186217";
          "36239410834198262339129557342130251912163884537720472258419319596614475181710";
          "30052101390787354520041305700295264045780224441445621717858661812094895346346";
          "21995102202891872269281007631877407834312363335297399149197261878759964569557";
          "2080131691710661742168916043433037277601198784836429928476841594059118749370";
          "42808036164195249275280963312025828986508786508614910971333518929197538998773";
          "5416726269860450738839660947415682809504169447200045382722531315472176837580";
          "35385358739760726215042915512119186540038118703012759099153921687310544107033";
          "27079498335589470388559429012071885383086029562052523482197446658383111072774";
          "14990895240018155420388973968063729735246061536340426651548494721699138380965";
          "44309562300548454609435401663522908994502966824080187553903158603409727800199";
        |],
        [|
          "28260403540575956442011209282235027627356413045516778063561130703408863908198";
          "17993250808843485497593981839623744555167943862527528485216257064528703538115";
          "28899493105874864372514833666497043025570659782554515014837391083549224357663";
          "51337256534645387155350783214024321835908156339022153213532792354442520429110";
          "36105366491256902485994568622814429160585987748654956293511966452904096000801";
          "43254842638818221613648051676914453096533481207151298911620538414624271037642";
          "30137483332361623247450591551673456707141812995305992129418088848770541392731";
          "51832887160148947731754609316481314302061191268958147833796630151024005898627";
          "43805495449265118506792567337086345883995710810828939619222069714626283759516";
          "43490811501888359185770575458084504215306703326085936961313644380351136142796";
          "45353492906491645466864766616545361422166823184893464158187486307135027299228";
          "25825572114166843629678422732449048165822431962411503253462472518376902250644";
          "26847540293236075734670790417576073958082755044059129980667062867535005919314";
          "27595037266661293341555794625370636649048746138720916959755452489901838331803";
          "50624068481465143084533854525326091050293490363529345388747088297570661644827";
          "43833176554968168233119024604069041530181053009400713400523917741660961832220";
        |],
        "16624801632831727463500847948913128838752380757508923660793891075002624508302",
        16 );
      ( [|
          "47158772775073549946552793332529610487862373214948589019241181027783090564927";
          "6969718530264830180568846645175610175808087246047159746318756753094302772749";
          "9686871355228041364920849477160310252453883661104177346095519526469628056477";
          "23701529205156171747824936169986903488212555374755529649712750610781499462060";
          "51871556544025649087958327041446036456025707894309969231504981069404849216674";
          "49777423642698315996233125696731960180992156573003897035030679033255179062106";
          "45193193026211585427447988721783950037458564208700328346100038403604928063434";
          "22127747185998681281737634883536464039523214813021737348626571438746574042602";
          "2436430336755214848244332120262587151205846315495966767110243193396303772169";
          "36030568404692126810397267528533249629542998741265626260816144992520627327404";
          "9733396005656647923887929901290339938184031472478829155648784527262943967802";
          "9232698019619721561468579430575787343679427145493378862256989115824088269321";
          "14667337314275170563143674471965744229406746565668692173766020639206764616232";
          "4730122363727714359627443666953284727545363839021842492384814113239394248107";
          "37600263337451873049904059627388200632297313939920669755923850829944793593331";
          "45293309035642456591052566417557511757964418893263771110015399573101864564094";
        |],
        [|
          "49159810856594417384836171575575789664328822394806699542327113948066763307898";
          "19513654523362036572945532378832190324412992065939315076003556719650225069528";
          "12400187722036186964464702144585831794106028402975104166770049464367024965836";
          "12729164750455352417868976767915518872789618782856391788646411468569638526867";
          "33894355416182050171353418403150653912631032966615091567798695189037336420208";
          "48124615888501419045682889152193022416530216136751831272743260607287479387889";
          "2671821870190640507797010788564244592122722767639756300432356882625084132990";
          "5747205261848282327286719985435091052484794664574217516630541561287563721611";
          "20484704306877713683149554254776007841626244646754279290228513586509772102603";
          "27810669340447093284494524394980216672115899286964546160004040217206390970278";
          "43245957846359230019664483425272837146730091593909167243373849997985752696625";
          "22694735552917590450918366121541571341777153373371464847736029264056462779996";
          "46382266250107013667570920582197666853273280950350971430513428795918673742221";
          "51480236715740128219868641008506780736289153092278122714177218949428874124399";
          "31214895100904294521197520923656651794655875018922463281556409805109003774848";
          "12370831947896207029058818364173897763780730291302175173295467787791916207957";
        |],
        "16624801632831727463500847948913128838752380757508923660793891075002624508302",
        16 );
    ]
  in
  List.iter
    (fun (points, expected_fft_results, root, n) ->
      let log = Z.(log2up @@ of_int n) in
      let root = Fr.of_string root in
      let points =
        Array.mapi (fun i v -> (Fr.of_string v, i)) points |> Array.to_list
      in
      let expected_fft_results = Array.map Fr.of_string expected_fft_results in
      let polynomial =
        Polynomial__Polynomial_c.Polynomial_unsafe.of_coefficients points
      in
      (* TODO: root is not the same as what computed by Domain.build,
         that's why we do this convoluted coversion. *)
      (*       let ru = *)
      (*         let module Fr_g = Polynomial.Fr_generation.Make (Fr) in *)
      (*         Fr_g.root_of_unity log *)
      (*       in *)
      (*       assert (Fr.eq ru (Fr.of_string root)) ; *)
      let domain =
        let module Domain = Polynomial__Domain.Domain_impl in
        let d = Domain.create log root in
        let module Domain = Polynomial__Domain.Domain_unsafe in
        Domain.of_carray d
      in
      let evaluation =
        let (_, a, l) =
          Polynomial__Evaluations_c.Evaluations_c_impl.evaluation_fft
            domain
            polynomial
        in
        Polynomial__Carray.to_array (a, l)
      in
      assert (Array.for_all2 Fr.eq expected_fft_results evaluation))
    vectors

let test_ifft_random () =
  let module Domain = Polynomial.Domain in
  let module Poly_c = Polynomial.Polynomial in
  let module Evaluations = Polynomial.Evaluations in
  let n = 16 in
  let log = Z.(log2up @@ of_int n) in
  let p = Poly_c.generate_random_polynomial n in
  let domain = Domain.build ~log in
  let fft_results = Evaluations.evaluation_fft domain p in
  let res = Evaluations.interpolation_fft domain fft_results in
  assert (Poly_c.equal p res)

let test_fft_interpolate () =
  let module Domain = Polynomial.Domain in
  let module Poly_c = Polynomial.Polynomial in
  let module Evaluations = Polynomial.Evaluations in
  let n = 16 in
  let log = Z.(log2up @@ of_int n) in
  let domain = Domain.build ~log in
  let scalars = Array.init n (fun _ -> Fr.random ()) in
  let polynomial = Evaluations.interpolation_fft2 domain scalars in
  Array.iteri
    (fun i x ->
      assert (Fr.eq x (Poly_c.evaluate polynomial (Domain.get domain i))))
    scalars

let test_fft_evaluate () =
  let module Domain = Polynomial__Domain in
  let module Poly_c = Polynomial__Polynomial_c in
  let module Evaluations = Polynomial__Evaluations_c.Evaluations_c_impl in
  let n = 16 in
  let log = Z.(log2up @@ of_int n) in
  let polynomial = Poly_c.generate_random_polynomial n in
  let domain = Domain.build ~log in
  let expected_result =
    Array.init n (fun i -> Poly_c.evaluate polynomial (Domain.get domain i))
  in
  let result =
    let (_, a, l) = Evaluations.evaluation_fft domain polynomial in
    Polynomial__Carray.to_array (a, l)
  in
  assert (Array.for_all2 Fr.eq result expected_result)

let test_domain_to_array () =
  let domain = Domain.build ~log:4 in
  let domain_caml = Domain.to_array domain in
  let domain_expected = Fr_generation.build_domain 4 in
  assert (Array.for_all2 Fr.eq domain_caml domain_expected)

let test_of_dense () =
  let array = Array.init 10 (fun _ -> Fr.random ()) in
  let array_res = Poly_c.of_dense array |> Poly_c.to_dense_coefficients in
  assert (Array.for_all2 Fr.eq array array_res)

let tests =
  let repetitions = 100 in
  List.map
    (fun (name, f) ->
      Alcotest.test_case name `Quick (fun () -> Helpers.repeat repetitions f))
    [
      ("build_domain", test_build_domain);
      ("vectors_fft", test_vectors_fft);
      ("ifft_random", test_ifft_random);
      ("get_sparse_coefficients", test_of_sparse_coefficients);
      ("copy", test_copy_polynomial);
      ("get_zero", test_get_zero);
      ("get_one", test_get_one);
      ("get_random", test_get_random);
      ("one", test_one);
      ("degree", test_degree);
      ("add", test_add);
      ("add_inplace", test_add_inplace);
      ("sub", test_sub);
      ("sub_inplace", test_sub_inplace);
      ("mul", test_mul);
      ("opposite", test_opposite);
      ("opposite_inplace", test_opposite_inplace);
      ("mul_by_scalar", test_mul_by_scalar);
      ("mul_by_scalar_inplace", test_mul_by_scalar_inplace);
      ("is_zero", test_is_zero);
      ("evaluate", test_evaluate);
      ("division_x_z", test_division_x_z);
      ("division_zs", test_division_zs);
      ("divsions_zs_limit_case", test_divsions_zs_limit_case);
      ("mul_zs", test_mul_zs);
      ("fft_evaluate", test_fft_evaluate);
      ("fft_interpolate", test_fft_interpolate);
      ("to_domain_array", test_domain_to_array);
      ("of_dense", test_of_dense);
    ]
