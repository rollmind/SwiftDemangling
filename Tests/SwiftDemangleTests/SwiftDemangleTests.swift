import XCTest
@testable import SwiftDemangle

final class SwiftDemangleTests: XCTestCase {
    func testPunycode() {
        let punycoded = "Proprostnemluvesky_uybCEdmaEBa"
        let encoded = "Pročprostěnemluvíčesky"
        XCTAssertEqual(Punycode(string: punycoded).decode(), encoded)
    }
    
    func testDemangle() throws {
        let mangled = "$s4test10returnsOptyxycSgxyScMYccSglF"
        let demangled = "test.returnsOpt<A>((@Swift.MainActor () -> A)?) -> (() -> A)?"
        let opts: DemangleOptions = .defaultOptions
        let result = try mangled.demangling(opts)
        XCTAssertEqual(result, demangled, "\n\(mangled) ---> \n\(result)\n\(demangled)")
    }
    
    func testDemangles() throws {
        try loadAndForEachMangles(self.mangles) { mangled, demangled in
            var opts: DemangleOptions = .defaultOptions
            var result = try mangled.demangling(opts)
            if result != demangled {
                opts.isClassify = true
                result = try mangled.demangling(opts)
            }
            if result != demangled {
                print("[TEST] for \(mangled) failed")
            } else {
                print("[TEST] for \(mangled) succeed")
            }
            XCTAssertEqual(result, demangled, "\n\(mangled) ---> \n\(result)\n\(demangled)")
        }
        
        try loadAndForEachMangles(self.simplified_mangles) { mangled, demangled in
            let opts: DemangleOptions = .simplifiedOptions
            let result = try mangled.demangling(opts)
            if result != demangled {
                print("[TEST] simplified demangle for \(mangled) failed")
            } else {
                print("[TEST] simplified demangle for \(mangled) succeed")
            }
            XCTAssertEqual(result, demangled, "\n\(mangled) ---> \n\(result)\n\(demangled)")
        }
    }
    
    func testFunctionSigSpecializationParamKind() throws {
        typealias Kind = FunctionSigSpecializationParamKind
        
        let kindOnly = Kind(rawValue: Kind.Kind.ClosureProp.rawValue)
        XCTAssertEqual(kindOnly.kind, .ClosureProp)
        XCTAssertTrue(kindOnly.optionSet.isEmpty)
        
        let optionSet: Kind.OptionSet = [.Dead, .GuaranteedToOwned]
        let kindAndOptionSet = Kind(rawValue: Kind.Kind.ClosureProp.rawValue | optionSet.rawValue)
        
        XCTAssertNotEqual(kindAndOptionSet.kind, .ClosureProp)
        XCTAssertNotEqual(kindAndOptionSet.kind, .BoxToStack)
        XCTAssertNotEqual(kindAndOptionSet.kind, .BoxToValue)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropFloat)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropFunction)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropGlobal)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropInteger)
        XCTAssertNotEqual(kindAndOptionSet.kind, .ConstantPropString)
        
        XCTAssertTrue(kindAndOptionSet.containOptions(.Dead))
        XCTAssertTrue(kindAndOptionSet.containOptions(.GuaranteedToOwned))
        XCTAssertFalse(kindAndOptionSet.containOptions(.ExistentialToGeneric))
        XCTAssertFalse(kindAndOptionSet.containOptions(.OwnedToGuaranteed))
        XCTAssertFalse(kindAndOptionSet.containOptions(.SROA))
        
        XCTAssertTrue(kindAndOptionSet.isValidOptionSet)
        
        let extraOptionSet: UInt = 1 << 11
        let extraOptionSetOnly = Kind(rawValue: extraOptionSet)
        XCTAssertFalse(extraOptionSetOnly.isValidOptionSet)
    }
    
    func loadAndForEachMangles(_ mangles: String, forEach handler: (_ mangled: String, _ demangled: String) throws -> Void) throws {
        for mangledPair in mangles.split(separator: "\n") where mangledPair.isNotEmpty && !mangledPair.hasPrefix("//") {
            var range = mangledPair.range(of: " ---> ")
            if range == nil {
                range = mangledPair.range(of: " --> ")
            }
            if range == nil {
                range = mangledPair.range(of: " -> ")
            }
            guard let range = range else { continue }
            let mangled = String(mangledPair[mangledPair.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let demangled = String(mangledPair[range.upperBound..<mangledPair.endIndex])
            try handler(mangled, demangled)
        }
    }
    
    let mangles: String = """
_TtBf32_ ---> Builtin.FPIEEE32
_TtBf64_ ---> Builtin.FPIEEE64
_TtBf80_ ---> Builtin.FPIEEE80
_TtBi32_ ---> Builtin.Int32
$sBf32_ ---> Builtin.FPIEEE32
$sBf64_ ---> Builtin.FPIEEE64
$sBf80_ ---> Builtin.FPIEEE80
$sBi32_ ---> Builtin.Int32
_TtBw ---> Builtin.Word
_TtBO ---> Builtin.UnknownObject
_TtBo ---> Builtin.NativeObject
_TtBp ---> Builtin.RawPointer
_TtBt ---> Builtin.SILToken
_TtBv4Bi8_ ---> Builtin.Vec4xInt8
_TtBv4Bf16_ ---> Builtin.Vec4xFloat16
_TtBv4Bp ---> Builtin.Vec4xRawPointer
_TtSa ---> Swift.Array
_TtSb ---> Swift.Bool
_TtSc ---> Swift.UnicodeScalar
_TtSd ---> Swift.Double
_TtSf ---> Swift.Float
_TtSi ---> Swift.Int
_TtSq ---> Swift.Optional
_TtSS ---> Swift.String
_TtSu ---> Swift.UInt
_TtGSPSi_ ---> Swift.UnsafePointer<Swift.Int>
_TtGSpSi_ ---> Swift.UnsafeMutablePointer<Swift.Int>
_TtSV ---> Swift.UnsafeRawPointer
_TtSv ---> Swift.UnsafeMutableRawPointer
_TtGSaSS_ ---> [Swift.String]
_TtGSqSS_ ---> Swift.String?
_TtGVs10DictionarySSSi_ ---> [Swift.String : Swift.Int]
_TtVs7CString ---> Swift.CString
_TtCSo8NSObject ---> __C.NSObject
_TtO6Monads6Either ---> Monads.Either
_TtbSiSu ---> @convention(block) (Swift.Int) -> Swift.UInt
_TtcSiSu ---> @convention(c) (Swift.Int) -> Swift.UInt
_TtbTSiSc_Su ---> @convention(block) (Swift.Int, Swift.UnicodeScalar) -> Swift.UInt
_TtcTSiSc_Su ---> @convention(c) (Swift.Int, Swift.UnicodeScalar) -> Swift.UInt
_TtFSiSu ---> (Swift.Int) -> Swift.UInt
_TtKSiSu ---> @autoclosure (Swift.Int) -> Swift.UInt
_TtFSiFScSu ---> (Swift.Int) -> (Swift.UnicodeScalar) -> Swift.UInt
_TtMSi ---> Swift.Int.Type
_TtP_ ---> Any
_TtP3foo3bar_ ---> foo.bar
_TtP3foo3barS_3bas_ ---> foo.bar & foo.bas
_TtTP3foo3barS_3bas_PS1__PS1_S_3zimS0___ ---> (foo.bar & foo.bas, foo.bas, foo.bas & foo.zim & foo.bar)
_TtRSi ---> inout Swift.Int
_TtTSiSu_ ---> (Swift.Int, Swift.UInt)
_TttSiSu_ ---> (Swift.Int, Swift.UInt...)
_TtT3fooSi3barSu_ ---> (foo: Swift.Int, bar: Swift.UInt)
_TturFxx ---> <A>(A) -> A
_TtuzrFT_T_ ---> <>() -> ()
_Ttu__rFxqd__ ---> <A><A1>(A) -> A1
_Ttu_z_rFxqd0__ ---> <A><><A2>(A) -> A2
_Ttu0_rFxq_ ---> <A, B>(A) -> B
_TtuRxs8RunciblerFxwx5Mince ---> <A where A: Swift.Runcible>(A) -> A.Mince
_TtuRxle64xs8RunciblerFxwx5Mince ---> <A where A: _Trivial(64), A: Swift.Runcible>(A) -> A.Mince
_TtuRxlE64_16rFxwx5Mince ---> <A where A: _Trivial(64, 16)>(A) -> A.Mince
_TtuRxlE64_32xs8RunciblerFxwx5Mince ---> <A where A: _Trivial(64, 32), A: Swift.Runcible>(A) -> A.Mince
_TtuRxlM64_16rFxwx5Mince ---> <A where A: _TrivialAtMost(64, 16)>(A) -> A.Mince
_TtuRxle64rFxwx5Mince ---> <A where A: _Trivial(64)>(A) -> A.Mince
_TtuRxlm64rFxwx5Mince ---> <A where A: _TrivialAtMost(64)>(A) -> A.Mince
_TtuRxlNrFxwx5Mince ---> <A where A: _NativeRefCountedObject>(A) -> A.Mince
_TtuRxlRrFxwx5Mince ---> <A where A: _RefCountedObject>(A) -> A.Mince
_TtuRxlUrFxwx5Mince ---> <A where A: _UnknownLayout>(A) -> A.Mince
_TtuRxs8RunciblerFxWx5Mince6Quince_ ---> <A where A: Swift.Runcible>(A) -> A.Mince.Quince
_TtuRxs8Runciblexs8FungiblerFxwxPS_5Mince ---> <A where A: Swift.Runcible, A: Swift.Fungible>(A) -> A.Swift.Runcible.Mince
_TtuRxCs22AbstractRuncingFactoryrFxx ---> <A where A: Swift.AbstractRuncingFactory>(A) -> A
_TtuRxs8Runciblewx5MincezxrFxx ---> <A where A: Swift.Runcible, A.Mince == A>(A) -> A
_TtuRxs8RuncibleWx5Mince6Quince_zxrFxx ---> <A where A: Swift.Runcible, A.Mince.Quince == A>(A) -> A
_Ttu0_Rxs8Runcible_S_wx5Minces8Fungiblew_S0_S1_rFxq_ ---> <A, B where A: Swift.Runcible, B: Swift.Runcible, A.Mince: Swift.Fungible, B.Mince: Swift.Fungible>(A) -> B
_Ttu0_Rx3Foo3BarxCS_3Bas_S0__S1_rT_ ---> <A, B where A: Foo.Bar, A: Foo.Bas, B: Foo.Bar, B: Foo.Bas> ()
_Tv3foo3barSi ---> foo.bar : Swift.Int
_TF3fooau3barSi ---> foo.bar.unsafeMutableAddressor : Swift.Int
_TF3foolu3barSi ---> foo.bar.unsafeAddressor : Swift.Int
_TF3fooaO3barSi ---> foo.bar.owningMutableAddressor : Swift.Int
_TF3foolO3barSi ---> foo.bar.owningAddressor : Swift.Int
_TF3fooao3barSi ---> foo.bar.nativeOwningMutableAddressor : Swift.Int
_TF3foolo3barSi ---> foo.bar.nativeOwningAddressor : Swift.Int
_TF3fooap3barSi ---> foo.bar.nativePinningMutableAddressor : Swift.Int
_TF3foolp3barSi ---> foo.bar.nativePinningAddressor : Swift.Int
_TF3foog3barSi ---> foo.bar.getter : Swift.Int
_TF3foos3barSi ---> foo.bar.setter : Swift.Int
_TFC3foo3bar3basfT3zimCS_3zim_T_ ---> foo.bar.bas(zim: foo.zim) -> ()
_TToFC3foo3bar3basfT3zimCS_3zim_T_ ---> {T:_TFC3foo3bar3basfT3zimCS_3zim_T_,C} @objc foo.bar.bas(zim: foo.zim) -> ()
_TTOFSC3fooFTSdSd_Sd ---> {T:_TFSC3fooFTSdSd_Sd} @nonobjc __C_Synthesized.foo(Swift.Double, Swift.Double) -> Swift.Double
_T03foo3barC3basyAA3zimCAE_tFTo ---> {T:_T03foo3barC3basyAA3zimCAE_tF,C} @objc foo.bar.bas(zim: foo.zim) -> ()
_T0SC3fooS2d_SdtFTO ---> {T:_T0SC3fooS2d_SdtF} @nonobjc __C_Synthesized.foo(Swift.Double, Swift.Double) -> Swift.Double
_$s3foo3barC3bas3zimyAaEC_tFTo ---> {T:_$s3foo3barC3bas3zimyAaEC_tF,C} @objc foo.bar.bas(zim: foo.zim) -> ()
_$sSC3fooyS2d_SdtFTO ---> {T:_$sSC3fooyS2d_SdtF} @nonobjc __C_Synthesized.foo(Swift.Double, Swift.Double) -> Swift.Double
_$S3foo3barC3bas3zimyAaEC_tFTo ---> {T:_$S3foo3barC3bas3zimyAaEC_tF,C} @objc foo.bar.bas(zim: foo.zim) -> ()
_$SSC3fooyS2d_SdtFTO ---> {T:_$SSC3fooyS2d_SdtF} @nonobjc __C_Synthesized.foo(Swift.Double, Swift.Double) -> Swift.Double
_$S3foo3barC3bas3zimyAaEC_tFTo ---> {T:_$S3foo3barC3bas3zimyAaEC_tF,C} @objc foo.bar.bas(zim: foo.zim) -> ()
_$SSC3fooyS2d_SdtFTO ---> {T:_$SSC3fooyS2d_SdtF} @nonobjc __C_Synthesized.foo(Swift.Double, Swift.Double) -> Swift.Double
_$sTA.123 ---> {T:} partial apply forwarder with unmangled suffix ".123"
$s4main3fooyySiFyyXEfU_TA.1 ---> {T:} closure #1 () -> () in main.foo(Swift.Int) -> ()partial apply forwarder with unmangled suffix ".1"
_TTDFC3foo3bar3basfT3zimCS_3zim_T_ ---> dynamic foo.bar.bas(zim: foo.zim) -> ()
_TFC3foo3bar3basfT3zimCS_3zim_T_ ---> foo.bar.bas(zim: foo.zim) -> ()
_TF3foooi1pFTCS_3barVS_3bas_OS_3zim ---> foo.+ infix(foo.bar, foo.bas) -> foo.zim
_TF3foooP1xFTCS_3barVS_3bas_OS_3zim ---> foo.^ postfix(foo.bar, foo.bas) -> foo.zim
_TFC3foo3barCfT_S0_ ---> foo.bar.__allocating_init() -> foo.bar
_TFC3foo3barcfT_S0_ ---> foo.bar.init() -> foo.bar
_TFC3foo3barD ---> foo.bar.__deallocating_deinit
_TFC3foo3bard ---> foo.bar.deinit
_TMPC3foo3bar ---> generic type metadata pattern for foo.bar
_TMnC3foo3bar ---> nominal type descriptor for foo.bar
_TMmC3foo3bar ---> metaclass for foo.bar
_TMC3foo3bar ---> type metadata for foo.bar
_TMfC3foo3bar ---> full type metadata for foo.bar
_TwalC3foo3bar ---> {C} allocateBuffer value witness for foo.bar
_TwcaC3foo3bar ---> {C} assignWithCopy value witness for foo.bar
_TwtaC3foo3bar ---> {C} assignWithTake value witness for foo.bar
_TwdeC3foo3bar ---> {C} deallocateBuffer value witness for foo.bar
_TwxxC3foo3bar ---> {C} destroy value witness for foo.bar
_TwXXC3foo3bar ---> {C} destroyBuffer value witness for foo.bar
_TwCPC3foo3bar ---> {C} initializeBufferWithCopyOfBuffer value witness for foo.bar
_TwCpC3foo3bar ---> {C} initializeBufferWithCopy value witness for foo.bar
_TwcpC3foo3bar ---> {C} initializeWithCopy value witness for foo.bar
_TwTKC3foo3bar ---> {C} initializeBufferWithTakeOfBuffer value witness for foo.bar
_TwTkC3foo3bar ---> {C} initializeBufferWithTake value witness for foo.bar
_TwtkC3foo3bar ---> {C} initializeWithTake value witness for foo.bar
_TwprC3foo3bar ---> {C} projectBuffer value witness for foo.bar
_TWVC3foo3bar ---> value witness table for foo.bar
_TWvdvC3foo3bar3basSi ---> direct field offset for foo.bar.bas : Swift.Int
_TWvivC3foo3bar3basSi ---> indirect field offset for foo.bar.bas : Swift.Int
_TWPC3foo3barS_8barrables ---> protocol witness table for foo.bar : foo.barrable in Swift
_TWaC3foo3barS_8barrableS_ ---> {C} protocol witness table accessor for foo.bar : foo.barrable in foo
_TWlC3foo3barS0_S_8barrableS_ ---> {C} lazy protocol witness table accessor for type foo.bar and conformance foo.bar : foo.barrable in foo
_TWLC3foo3barS0_S_8barrableS_ ---> lazy protocol witness table cache variable for type foo.bar and conformance foo.bar : foo.barrable in foo
_TWGC3foo3barS_8barrableS_ ---> generic protocol witness table for foo.bar : foo.barrable in foo
_TWIC3foo3barS_8barrableS_ ---> {C} instantiation function for generic protocol witness table for foo.bar : foo.barrable in foo
_TWtC3foo3barS_8barrableS_4fred ---> {C} associated type metadata accessor for fred in foo.bar : foo.barrable in foo
_TWTC3foo3barS_8barrableS_4fredS_6thomas ---> {C} associated type witness table accessor for fred : foo.thomas in foo.bar : foo.barrable in foo
_TFSCg5greenVSC5Color ---> __C_Synthesized.green.getter : __C_Synthesized.Color
_TIF1t1fFT1iSi1sSS_T_A_ ---> default argument 0 of t.f(i: Swift.Int, s: Swift.String) -> ()
_TIF1t1fFT1iSi1sSS_T_A0_ ---> default argument 1 of t.f(i: Swift.Int, s: Swift.String) -> ()
_TFSqcfT_GSqx_ ---> Swift.Optional.init() -> A?
_TF21class_bound_protocols32class_bound_protocol_compositionFT1xPS_10ClassBoundS_13NotClassBound__PS0_S1__ ---> class_bound_protocols.class_bound_protocol_composition(x: class_bound_protocols.ClassBound & class_bound_protocols.NotClassBound) -> class_bound_protocols.ClassBound & class_bound_protocols.NotClassBound
_TtZZ ---> _TtZZ
_TtB ---> _TtB
_TtBSi ---> _TtBSi
_TtBx ---> _TtBx
_TtC ---> _TtC
_TtT ---> _TtT
_TtTSi ---> _TtTSi
_TtQd_ ---> _TtQd_
_TtU__FQo_Si ---> _TtU__FQo_Si
_TtU__FQD__Si ---> _TtU__FQD__Si
_TtU___FQ_U____FQd0__T_ ---> _TtU___FQ_U____FQd0__T_
_TtU___FQ_U____FQd_1_T_ ---> _TtU___FQ_U____FQd_1_T_
_TtU___FQ_U____FQ2_T_ ---> _TtU___FQ_U____FQ2_T_
_Tw ---> _Tw
_TWa ---> _TWa
_Twal ---> _Twal
_T ---> _T
_TTo ---> {T:_T} _TTo
_TC ---> _TC
_TM ---> _TM
_TM ---> _TM
_TW ---> _TW
_TWV ---> _TWV
_TWo ---> _TWo
_TWv ---> _TWv
_TWvd ---> _TWvd
_TWvi ---> _TWvi
_TWvx ---> _TWvx
_TtVCC4main3Foo4Ding3Str ---> main.Foo.Ding.Str
_TFVCC6nested6AClass12AnotherClass7AStruct9aFunctionfT1aSi_S2_ ---> nested.AClass.AnotherClass.AStruct.aFunction(a: Swift.Int) -> nested.AClass.AnotherClass.AStruct
_TtXwC10attributes10SwiftClass ---> weak attributes.SwiftClass
_TtXoC10attributes10SwiftClass ---> unowned attributes.SwiftClass
_TtERR ---> <ERROR TYPE>
_TtGSqGSaC5sugar7MyClass__ ---> [sugar.MyClass]?
_TtGSaGSqC5sugar7MyClass__ ---> [sugar.MyClass?]
_TtaC9typealias5DWARF9DIEOffset ---> typealias.DWARF.DIEOffset
_Tta1t5Alias ---> t.Alias
_Ttas3Int ---> Swift.Int
_TTRXFo_dSc_dSb_XFo_iSc_iSb_ ---> reabstraction thunk helper from @callee_owned (@in Swift.UnicodeScalar) -> (@out Swift.Bool) to @callee_owned (@unowned Swift.UnicodeScalar) -> (@unowned Swift.Bool)
_TTRXFo_dSi_dGSqSi__XFo_iSi_iGSqSi__ ---> reabstraction thunk helper from @callee_owned (@in Swift.Int) -> (@out Swift.Int?) to @callee_owned (@unowned Swift.Int) -> (@unowned Swift.Int?)
_TTRGrXFo_iV18switch_abstraction1A_ix_XFo_dS0__ix_ ---> reabstraction thunk helper <A> from @callee_owned (@unowned switch_abstraction.A) -> (@out A) to @callee_owned (@in switch_abstraction.A) -> (@out A)
_TFCF5types1gFT1bSb_T_L0_10Collection3zimfT_T_ ---> zim() -> () in Collection #2 in types.g(b: Swift.Bool) -> ()
_TFF17capture_promotion22test_capture_promotionFT_FT_SiU_FT_Si_promote0 ---> closure #1 () -> Swift.Int in capture_promotion.test_capture_promotion() -> () -> Swift.Int with unmangled suffix "_promote0"
_TFIVs8_Processi10_argumentsGSaSS_U_FT_GSaSS_ ---> _arguments : [Swift.String] in variable initialization expression of Swift._Process with unmangled suffix "U_FT_GSaSS_"
_TFIvVs8_Process10_argumentsGSaSS_iU_FT_GSaSS_ ---> closure #1 () -> [Swift.String] in variable initialization expression of Swift._Process._arguments : [Swift.String]
_TFCSo1AE ---> __C.A.__ivar_destroyer
_TFCSo1Ae ---> __C.A.__ivar_initializer
_TTWC13call_protocol1CS_1PS_FS1_3foofT_Si ---> protocol witness for call_protocol.P.foo() -> Swift.Int in conformance call_protocol.C : call_protocol.P in call_protocol
_T013call_protocol1CCAA1PA2aDP3fooSiyFTW ---> {T:} protocol witness for call_protocol.P.foo() -> Swift.Int in conformance call_protocol.C : call_protocol.P in call_protocol
_TFC12dynamic_self1X1ffT_DS0_ ---> dynamic_self.X.f() -> Self
_TTSg5Si___TFSqcfT_GSqx_ ---> generic specialization <Swift.Int> of Swift.Optional.init() -> A?
_TTSgq5Si___TFSqcfT_GSqx_ ---> generic specialization <serialized, Swift.Int> of Swift.Optional.init() -> A?
_TTSg5SiSis3Foos_Sf___TFSqcfT_GSqx_ ---> generic specialization <Swift.Int with Swift.Int : Swift.Foo in Swift, Swift.Float> of Swift.Optional.init() -> A?
_TTSg5Si_Sf___TFSqcfT_GSqx_ ---> generic specialization <Swift.Int, Swift.Float> of Swift.Optional.init() -> A?
_TTSg5Si_Sf___TFSqcfT_GSqx_ ---> generic specialization <Swift.Int, Swift.Float> of Swift.Optional.init() -> A?
_TTSgS ---> _TTSgS
_TTSg5S ---> _TTSg5S
_TTSgSi ---> _TTSgSi
_TTSg5Si ---> _TTSg5Si
_TTSgSi_ ---> _TTSgSi_
_TTSgSi__ ---> _TTSgSi__
_TTSgSiS_ ---> _TTSgSiS_
_TTSgSi__xyz ---> _TTSgSi__xyz
_TTSr5Si___TF4test7genericurFxx ---> generic not re-abstracted specialization <Swift.Int> of test.generic<A>(A) -> A
_TTSrq5Si___TF4test7genericurFxx ---> generic not re-abstracted specialization <serialized, Swift.Int> of test.generic<A>(A) -> A
_TPA__TTRXFo_oSSoSS_dSb_XFo_iSSiSS_dSb_ ---> {T:_TTRXFo_oSSoSS_dSb_XFo_iSSiSS_dSb_} partial apply forwarder for reabstraction thunk helper from @callee_owned (@in Swift.String, @in Swift.String) -> (@unowned Swift.Bool) to @callee_owned (@owned Swift.String, @owned Swift.String) -> (@unowned Swift.Bool)
_TPAo__TTRGrXFo_dGSPx__dGSPx_zoPs5Error__XFo_iGSPx__iGSPx_zoPS___ ---> {T:_TTRGrXFo_dGSPx__dGSPx_zoPs5Error__XFo_iGSPx__iGSPx_zoPS___} partial apply ObjC forwarder for reabstraction thunk helper <A> from @callee_owned (@in Swift.UnsafePointer<A>) -> (@out Swift.UnsafePointer<A>, @error @owned Swift.Error) to @callee_owned (@unowned Swift.UnsafePointer<A>) -> (@unowned Swift.UnsafePointer<A>, @error @owned Swift.Error)
_T0S2SSbIxxxd_S2SSbIxiid_TRTA ---> {T:_T0S2SSbIxxxd_S2SSbIxiid_TR} partial apply forwarder for reabstraction thunk helper from @callee_owned (@owned Swift.String, @owned Swift.String) -> (@unowned Swift.Bool) to @callee_owned (@in Swift.String, @in Swift.String) -> (@unowned Swift.Bool)
_T0SPyxGAAs5Error_pIxydzo_A2AsAB_pIxirzo_lTRTa ---> {T:_T0SPyxGAAs5Error_pIxydzo_A2AsAB_pIxirzo_lTR} partial apply ObjC forwarder for reabstraction thunk helper <A> from @callee_owned (@unowned Swift.UnsafePointer<A>) -> (@unowned Swift.UnsafePointer<A>, @error @owned Swift.Error) to @callee_owned (@in Swift.UnsafePointer<A>) -> (@out Swift.UnsafePointer<A>, @error @owned Swift.Error)
_TiC4Meow5MyCls9subscriptFT1iSi_Sf ---> Meow.MyCls.subscript(i: Swift.Int) -> Swift.Float
_TF8manglingX22egbpdajGbuEbxfgehfvwxnFT_T_ ---> mangling.ليهمابتكلموشعربي؟() -> ()
_TF8manglingX24ihqwcrbEcvIaIdqgAFGpqjyeFT_T_ ---> mangling.他们为什么不说中文() -> ()
_TF8manglingX27ihqwctvzcJBfGFJdrssDxIboAybFT_T_ ---> mangling.他們爲什麽不說中文() -> ()
_TF8manglingX30Proprostnemluvesky_uybCEdmaEBaFT_T_ ---> mangling.Pročprostěnemluvíčesky() -> ()
_TF8manglingXoi7p_qcaDcFTSiSi_Si ---> mangling.«+» infix(Swift.Int, Swift.Int) -> Swift.Int
_TF8manglingoi2qqFTSiSi_T_ ---> mangling.?? infix(Swift.Int, Swift.Int) -> ()
_TFE11ext_structAV11def_structA1A4testfT_T_ ---> (extension in ext_structA):def_structA.A.test() -> ()
_TF13devirt_accessP5_DISC15getPrivateClassFT_CS_P5_DISC12PrivateClass ---> devirt_access.(getPrivateClass in _DISC)() -> devirt_access.(PrivateClass in _DISC)
_TF4mainP5_mainX3wxaFT_T_ ---> main.(λ in _main)() -> ()
_TF4mainP5_main3abcFT_aS_P5_DISC3xyz ---> main.(abc in _main)() -> main.(xyz in _DISC)
_TtPMP_ ---> Any.Type
_TFCs13_NSSwiftArray29canStoreElementsOfDynamicTypefPMP_Sb ---> Swift._NSSwiftArray.canStoreElementsOfDynamicType(Any.Type) -> Swift.Bool
_TFCs13_NSSwiftArrayg17staticElementTypePMP_ ---> Swift._NSSwiftArray.staticElementType.getter : Any.Type
_TFCs17_DictionaryMirrorg9valueTypePMP_ ---> Swift._DictionaryMirror.valueType.getter : Any.Type
_TTSf1cl35_TFF7specgen6callerFSiT_U_FTSiSi_T_Si___TF7specgen12take_closureFFTSiSi_T_T_ ---> function signature specialization <Arg[0] = [Closure Propagated : closure #1 (Swift.Int, Swift.Int) -> () in specgen.caller(Swift.Int) -> (), Argument Types : [Swift.Int]> of specgen.take_closure((Swift.Int, Swift.Int) -> ()) -> ()
_TTSfq1cl35_TFF7specgen6callerFSiT_U_FTSiSi_T_Si___TF7specgen12take_closureFFTSiSi_T_T_ ---> function signature specialization <serialized, Arg[0] = [Closure Propagated : closure #1 (Swift.Int, Swift.Int) -> () in specgen.caller(Swift.Int) -> (), Argument Types : [Swift.Int]> of specgen.take_closure((Swift.Int, Swift.Int) -> ()) -> ()
_TTSf1cl35_TFF7specgen6callerFSiT_U_FTSiSi_T_Si___TTSg5Si___TF7specgen12take_closureFFTSiSi_T_T_ ---> function signature specialization <Arg[0] = [Closure Propagated : closure #1 (Swift.Int, Swift.Int) -> () in specgen.caller(Swift.Int) -> (), Argument Types : [Swift.Int]> of generic specialization <Swift.Int> of specgen.take_closure((Swift.Int, Swift.Int) -> ()) -> ()
_TTSg5Si___TTSf1cl35_TFF7specgen6callerFSiT_U_FTSiSi_T_Si___TF7specgen12take_closureFFTSiSi_T_T_ ---> generic specialization <Swift.Int> of function signature specialization <Arg[0] = [Closure Propagated : closure #1 (Swift.Int, Swift.Int) -> () in specgen.caller(Swift.Int) -> (), Argument Types : [Swift.Int]> of specgen.take_closure((Swift.Int, Swift.Int) -> ()) -> ()
_TTSf1cpfr24_TF8capturep6helperFSiT__n___TTRXFo_dSi_dT__XFo_iSi_dT__ ---> function signature specialization <Arg[0] = [Constant Propagated Function : capturep.helper(Swift.Int) -> ()]> of reabstraction thunk helper from @callee_owned (@in Swift.Int) -> (@unowned ()) to @callee_owned (@unowned Swift.Int) -> (@unowned ())
_TTSf1cpfr24_TF8capturep6helperFSiT__n___TTRXFo_dSi_DT__XFo_iSi_DT__ ---> function signature specialization <Arg[0] = [Constant Propagated Function : capturep.helper(Swift.Int) -> ()]> of reabstraction thunk helper from @callee_owned (@in Swift.Int) -> (@unowned_inner_pointer ()) to @callee_owned (@unowned Swift.Int) -> (@unowned_inner_pointer ())
_TTSf1cpi0_cpfl0_cpse0v4u123_cpg53globalinit_33_06E7F1D906492AE070936A9B58CBAE1C_token8_cpfr36_TFtest_capture_propagation2_closure___TF7specgen12take_closureFFTSiSi_T_T_ ---> function signature specialization <Arg[0] = [Constant Propagated Integer : 0], Arg[1] = [Constant Propagated Float : 0], Arg[2] = [Constant Propagated String : u8'u123'], Arg[3] = [Constant Propagated Global : globalinit_33_06E7F1D906492AE070936A9B58CBAE1C_token8], Arg[4] = [Constant Propagated Function : _TFtest_capture_propagation2_closure]> of specgen.take_closure((Swift.Int, Swift.Int) -> ()) -> ()
_TTSf0gs___TFVs17_LegacyStringCore15_invariantCheckfT_T_ ---> function signature specialization <Arg[0] = Owned To Guaranteed and Exploded> of Swift._LegacyStringCore._invariantCheck() -> ()
_TTSf2g___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Owned To Guaranteed> of function signature specialization <Arg[0] = Exploded, Arg[1] = Dead> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TTSf2dg___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Dead and Owned To Guaranteed> of function signature specialization <Arg[0] = Exploded, Arg[1] = Dead> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TTSf2dgs___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Dead and Owned To Guaranteed and Exploded> of function signature specialization <Arg[0] = Exploded, Arg[1] = Dead> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TTSf3d_i_d_i_d_i___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Dead, Arg[1] = Value Promoted from Box, Arg[2] = Dead, Arg[3] = Value Promoted from Box, Arg[4] = Dead, Arg[5] = Value Promoted from Box> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TTSf3d_i_n_i_d_i___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Dead, Arg[1] = Value Promoted from Box, Arg[3] = Value Promoted from Box, Arg[4] = Dead, Arg[5] = Value Promoted from Box> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TFIZvV8mangling10HasVarInit5stateSbiu_KT_Sb ---> implicit closure #1 : @autoclosure () -> Swift.Bool in variable initialization expression of static mangling.HasVarInit.state : Swift.Bool
_TFFV23interface_type_mangling18GenericTypeContext23closureInGenericContexturFqd__T_L_3fooFTqd__x_T_ ---> foo #1 (A1, A) -> () in interface_type_mangling.GenericTypeContext.closureInGenericContext<A>(A1) -> ()
_TFFV23interface_type_mangling18GenericTypeContextg31closureInGenericPropertyContextxL_3fooFT_x ---> foo #1 () -> A in interface_type_mangling.GenericTypeContext.closureInGenericPropertyContext.getter : A
_TTWurGV23interface_type_mangling18GenericTypeContextx_S_18GenericWitnessTestS_FS1_23closureInGenericContextuRxS1_rfqd__T_ ---> protocol witness for interface_type_mangling.GenericWitnessTest.closureInGenericContext<A where A: interface_type_mangling.GenericWitnessTest>(A1) -> () in conformance <A> interface_type_mangling.GenericTypeContext<A> : interface_type_mangling.GenericWitnessTest in interface_type_mangling
_TTWurGV23interface_type_mangling18GenericTypeContextx_S_18GenericWitnessTestS_FS1_g31closureInGenericPropertyContextwx3Tee ---> protocol witness for interface_type_mangling.GenericWitnessTest.closureInGenericPropertyContext.getter : A.Tee in conformance <A> interface_type_mangling.GenericTypeContext<A> : interface_type_mangling.GenericWitnessTest in interface_type_mangling
_TTWurGV23interface_type_mangling18GenericTypeContextx_S_18GenericWitnessTestS_FS1_16twoParamsAtDepthu0_RxS1_rfTqd__1yqd_0__T_ ---> protocol witness for interface_type_mangling.GenericWitnessTest.twoParamsAtDepth<A, B where A: interface_type_mangling.GenericWitnessTest>(A1, y: B1) -> () in conformance <A> interface_type_mangling.GenericTypeContext<A> : interface_type_mangling.GenericWitnessTest in interface_type_mangling
_TFC3red11BaseClassEHcfzT1aSi_S0_ ---> red.BaseClassEH.init(a: Swift.Int) throws -> red.BaseClassEH
_TFe27mangling_generic_extensionsRxS_8RunciblerVS_3Foog1aSi ---> (extension in mangling_generic_extensions):mangling_generic_extensions.Foo<A where A: mangling_generic_extensions.Runcible>.a.getter : Swift.Int
_TFe27mangling_generic_extensionsRxS_8RunciblerVS_3Foog1bx ---> (extension in mangling_generic_extensions):mangling_generic_extensions.Foo<A where A: mangling_generic_extensions.Runcible>.b.getter : A
_TTRXFo_iT__iT_zoPs5Error__XFo__dT_zoPS___ ---> reabstraction thunk helper from @callee_owned () -> (@unowned (), @error @owned Swift.Error) to @callee_owned (@in ()) -> (@out (), @error @owned Swift.Error)
_TFE1a ---> _TFE1a
_TF21$__lldb_module_for_E0au3$E0Ps5Error_ ---> $__lldb_module_for_E0.$E0.unsafeMutableAddressor : Swift.Error
_TMps10Comparable ---> protocol descriptor for Swift.Comparable
_TFC4testP33_83378C430F65473055F1BD53F3ADCDB71C5doFoofT_T_ ---> test.(C in _83378C430F65473055F1BD53F3ADCDB7).doFoo() -> ()
_TFVV15nested_generics5Lunch6DinnerCfT11firstCoursex12secondCourseGSqqd___9leftoversx14transformationFxqd___GS1_x_qd___ ---> nested_generics.Lunch.Dinner.init(firstCourse: A, secondCourse: A1?, leftovers: A, transformation: (A) -> A1) -> nested_generics.Lunch<A>.Dinner<A1>
_TFVFC15nested_generics7HotDogs11applyRelishFT_T_L_6RelishCfT8materialx_GS1_x_ ---> init(material: A) -> Relish #1 in nested_generics.HotDogs.applyRelish() -> ()<A> in Relish #1 in nested_generics.HotDogs.applyRelish() -> ()
_TFVFE15nested_genericsSS3fooFT_T_L_6CheeseCfT8materialx_GS0_x_ ---> init(material: A) -> Cheese #1 in (extension in nested_generics):Swift.String.foo() -> ()<A> in Cheese #1 in (extension in nested_generics):Swift.String.foo() -> ()
_TTWOE5imojiCSo5Imoji14ImojiMatchRankS_9RankValueS_FS2_g9rankValueqq_Ss16RawRepresentable8RawValue ---> _TTWOE5imojiCSo5Imoji14ImojiMatchRankS_9RankValueS_FS2_g9rankValueqq_Ss16RawRepresentable8RawValue
_T0s17MutableCollectionP1asAARzs012RandomAccessB0RzsAA11SubSequences013BidirectionalB0PRpzsAdHRQlE06rotatecD05Indexs01_A9IndexablePQzAM15shiftingToStart_tFAJs01_J4BasePQzAQcfU_ ---> closure #1 (A.Swift._IndexableBase.Index) -> A.Swift._IndexableBase.Index in (extension in a):Swift.MutableCollection<A where A: Swift.MutableCollection, A: Swift.RandomAccessCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.MutableCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.RandomAccessCollection>.rotateRandomAccess(shiftingToStart: A.Swift._MutableIndexable.Index) -> A.Swift._MutableIndexable.Index
_$Ss17MutableCollectionP1asAARzs012RandomAccessB0RzsAA11SubSequences013BidirectionalB0PRpzsAdHRQlE06rotatecD015shiftingToStart5Indexs01_A9IndexablePQzAN_tFAKs01_M4BasePQzAQcfU_ ---> closure #1 (A.Swift._IndexableBase.Index) -> A.Swift._IndexableBase.Index in (extension in a):Swift.MutableCollection<A where A: Swift.MutableCollection, A: Swift.RandomAccessCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.MutableCollection, A.Swift.BidirectionalCollection.SubSequence: Swift.RandomAccessCollection>.rotateRandomAccess(shiftingToStart: A.Swift._MutableIndexable.Index) -> A.Swift._MutableIndexable.Index
_T03foo4_123ABTf3psbpsb_n ---> function signature specialization <Arg[0] = [Constant Propagated String : u8'123'], Arg[1] = [Constant Propagated String : u8'123']> of foo
_T04main5innerys5Int32Vz_yADctF25closure_with_box_argumentxz_Bi32__lXXTf1nc_n ---> function signature specialization <Arg[1] = [Closure Propagated : closure_with_box_argument, Argument Types : [<A> { var A } <Builtin.Int32>]> of main.inner(inout Swift.Int32, (Swift.Int32) -> ()) -> ()
_$S4main5inneryys5Int32Vz_yADctF25closure_with_box_argumentxz_Bi32__lXXTf1nc_n ---> function signature specialization <Arg[1] = [Closure Propagated : closure_with_box_argument, Argument Types : [<A> { var A } <Builtin.Int32>]> of main.inner(inout Swift.Int32, (Swift.Int32) -> ()) -> ()
_T03foo6testityyyc_yyctF1a1bTf3pfpf_n ---> function signature specialization <Arg[0] = [Constant Propagated Function : a], Arg[1] = [Constant Propagated Function : b]> of foo.testit(() -> (), () -> ()) -> ()
_$S3foo6testityyyyc_yyctF1a1bTf3pfpf_n ---> function signature specialization <Arg[0] = [Constant Propagated Function : a], Arg[1] = [Constant Propagated Function : b]> of foo.testit(() -> (), () -> ()) -> ()
_SocketJoinOrLeaveMulticast ---> _SocketJoinOrLeaveMulticast
_T0s10DictionaryV3t17E6Index2V1loiSbAEyxq__G_AGtFZ ---> static (extension in t17):Swift.Dictionary.Index2.< infix((extension in t17):[A : B].Index2, (extension in t17):[A : B].Index2) -> Swift.Bool
_T08mangling14varargsVsArrayySi3arrd_SS1ntF ---> mangling.varargsVsArray(arr: Swift.Int..., n: Swift.String) -> ()
_T08mangling14varargsVsArrayySaySiG3arr_SS1ntF ---> mangling.varargsVsArray(arr: [Swift.Int], n: Swift.String) -> ()
_T08mangling14varargsVsArrayySaySiG3arrd_SS1ntF ---> mangling.varargsVsArray(arr: [Swift.Int]..., n: Swift.String) -> ()
_T08mangling14varargsVsArrayySi3arrd_tF ---> mangling.varargsVsArray(arr: Swift.Int...) -> ()
_T08mangling14varargsVsArrayySaySiG3arrd_tF ---> mangling.varargsVsArray(arr: [Swift.Int]...) -> ()
_$Ss10DictionaryV3t17E6Index2V1loiySbAEyxq__G_AGtFZ ---> static (extension in t17):Swift.Dictionary.Index2.< infix((extension in t17):[A : B].Index2, (extension in t17):[A : B].Index2) -> Swift.Bool
_$S8mangling14varargsVsArray3arr1nySid_SStF ---> mangling.varargsVsArray(arr: Swift.Int..., n: Swift.String) -> ()
_$S8mangling14varargsVsArray3arr1nySaySiG_SStF ---> mangling.varargsVsArray(arr: [Swift.Int], n: Swift.String) -> ()
_$S8mangling14varargsVsArray3arr1nySaySiGd_SStF ---> mangling.varargsVsArray(arr: [Swift.Int]..., n: Swift.String) -> ()
_$S8mangling14varargsVsArray3arrySid_tF ---> mangling.varargsVsArray(arr: Swift.Int...) -> ()
_$S8mangling14varargsVsArray3arrySaySiGd_tF ---> mangling.varargsVsArray(arr: [Swift.Int]...) -> ()
_T0s13_UnicodeViewsVss22RandomAccessCollectionRzs0A8EncodingR_11SubSequence_5IndexQZAFRtzsAcERpzAE_AEQZAIRSs15UnsignedInteger8Iterator_7ElementRPzAE_AlMQZANRS13EncodedScalar_AlMQY_AORSr0_lE13CharacterViewVyxq__G ---> (extension in Swift):Swift._UnicodeViews<A, B><A, B where A: Swift.RandomAccessCollection, B: Swift.UnicodeEncoding, A.Index == A.SubSequence.Index, A.SubSequence: Swift.RandomAccessCollection, A.SubSequence == A.SubSequence.SubSequence, A.Iterator.Element: Swift.UnsignedInteger, A.Iterator.Element == A.SubSequence.Iterator.Element, A.SubSequence.Iterator.Element == B.EncodedScalar.Iterator.Element>.CharacterView
_T010Foundation11MeasurementV12SimulatorKitSo9UnitAngleCRszlE11OrientationO2eeoiSbAcDEAGOyAF_G_AKtFZ ---> static (extension in SimulatorKit):Foundation.Measurement<A where A == __C.UnitAngle>.Orientation.== infix((extension in SimulatorKit):Foundation.Measurement<__C.UnitAngle>.Orientation, (extension in SimulatorKit):Foundation.Measurement<__C.UnitAngle>.Orientation) -> Swift.Bool
_$S10Foundation11MeasurementV12SimulatorKitSo9UnitAngleCRszlE11OrientationO2eeoiySbAcDEAGOyAF_G_AKtFZ ---> static (extension in SimulatorKit):Foundation.Measurement<A where A == __C.UnitAngle>.Orientation.== infix((extension in SimulatorKit):Foundation.Measurement<__C.UnitAngle>.Orientation, (extension in SimulatorKit):Foundation.Measurement<__C.UnitAngle>.Orientation) -> Swift.Bool
_T04main1_yyF ---> main._() -> ()
_T04test6testitSiyt_tF ---> test.testit(()) -> Swift.Int
_$S4test6testitySiyt_tF ---> test.testit(()) -> Swift.Int
_T08_ElementQzSbs5Error_pIxxdzo_ABSbsAC_pIxidzo_s26RangeReplaceableCollectionRzABRLClTR ---> {T:} reabstraction thunk helper <A where A: Swift.RangeReplaceableCollection, A._Element: AnyObject> from @callee_owned (@owned A._Element) -> (@unowned Swift.Bool, @error @owned Swift.Error) to @callee_owned (@in A._Element) -> (@unowned Swift.Bool, @error @owned Swift.Error)
_T0Ix_IyB_Tr ---> {T:} reabstraction thunk from @callee_owned () -> () to @callee_unowned @convention(block) () -> ()
_T0Rml ---> _T0Rml
_T0Tk ---> _T0Tk
_T0A8 ---> _T0A8
_T0s30ReversedRandomAccessCollectionVyxGTfq3nnpf_nTfq1cn_nTfq4x_n ---> _T0s30ReversedRandomAccessCollectionVyxGTfq3nnpf_nTfq1cn_nTfq4x_n
_T03abc6testitySiFTm ---> merged abc.testit(Swift.Int) -> ()
_T04main4TestCACSi1x_tc6_PRIV_Llfc ---> main.Test.(in _PRIV_).init(x: Swift.Int) -> main.Test
_$S3abc6testityySiFTm ---> merged abc.testit(Swift.Int) -> ()
_$S4main4TestC1xACSi_tc6_PRIV_Llfc ---> main.Test.(in _PRIV_).init(x: Swift.Int) -> main.Test
_T0SqWOy.17 ---> outlined copy of Swift.Optional with unmangled suffix ".17"
_T03nix6testitSaySiGyFTv_ ---> outlined variable #0 of nix.testit() -> [Swift.Int]
_T03nix6testitSaySiGyFTv0_ ---> outlined variable #1 of nix.testit() -> [Swift.Int]
_T0So11UITextFieldC4textSSSgvgToTepb_ ---> outlined bridged method (pb) of @objc __C.UITextField.text.getter : Swift.String?
_T0So11UITextFieldC4textSSSgvgToTeab_ ---> outlined bridged method (ab) of @objc __C.UITextField.text.getter : Swift.String?
$sSo5GizmoC11doSomethingyypSgSaySSGSgFToTembgnn_ ---> outlined bridged method (mbgnn) of @objc __C.Gizmo.doSomething([Swift.String]?) -> Any?
_T04test1SVyxGAA1RA2A1ZRzAA1Y2ZZRpzl1A_AhaGPWT ---> {C} associated type witness table accessor for A.ZZ : test.Y in <A where A: test.Z, A.ZZ: test.Y> test.S<A> : test.R in test
_T0s24_UnicodeScalarExceptions33_0E4228093681F6920F0AB2E48B4F1C69LLVACycfC ---> {T:_T0s24_UnicodeScalarExceptions33_0E4228093681F6920F0AB2E48B4F1C69LLVACycfc} Swift.(_UnicodeScalarExceptions in _0E4228093681F6920F0AB2E48B4F1C69).init() -> Swift.(_UnicodeScalarExceptions in _0E4228093681F6920F0AB2E48B4F1C69)
_T0D ---> _T0D
_T0s18EnumeratedIteratorVyxGs8Sequencess0B8ProtocolRzlsADP5splitSay03SubC0QzGSi9maxSplits_Sb25omittingEmptySubsequencesSb7ElementQzKc14whereSeparatortKFTW ---> {T:} protocol witness for Swift.Sequence.split(maxSplits: Swift.Int, omittingEmptySubsequences: Swift.Bool, whereSeparator: (A.Element) throws -> Swift.Bool) throws -> [A.SubSequence] in conformance <A where A: Swift.IteratorProtocol> Swift.EnumeratedIterator<A> : Swift.Sequence in Swift
_T0s3SetVyxGs10CollectiotySivm ---> _T0s3SetVyxGs10CollectiotySivm
_S$s3SetVyxGs10CollectiotySivm ---> _S$s3SetVyxGs10CollectiotySivm
_T0s18ReversedCollectionVyxGs04LazyB8ProtocolfC ---> _T0s18ReversedCollectionVyxGs04LazyB8ProtocolfC
_S$s18ReversedCollectionVyxGs04LazyB8ProtocolfC ---> _S$s18ReversedCollectionVyxGs04LazyB8ProtocolfC
_T0iW ---> _T0iW
_S$iW ---> _S$iW
_T0s5print_9separator10terminatoryypfC ---> _T0s5print_9separator10terminatoryypfC
_S$s5print_9separator10terminatoryypfC ---> _S$s5print_9separator10terminatoryypfC
_T0So13GenericOptionas8HashableSCsACP9hashValueSivgTW ---> {T:} protocol witness for Swift.Hashable.hashValue.getter : Swift.Int in conformance __C.GenericOption : Swift.Hashable in __C_Synthesized
_T0So11CrappyColorVs16RawRepresentableSCMA ---> reflection metadata associated type descriptor __C.CrappyColor : Swift.RawRepresentable in __C_Synthesized
$S28protocol_conformance_records15NativeValueTypeVAA8RuncibleAAMc ---> protocol conformance descriptor for protocol_conformance_records.NativeValueType : protocol_conformance_records.Runcible in protocol_conformance_records
$SSC9SomeErrorLeVD ---> __C_Synthesized.related decl 'e' for SomeError
$s20mangling_retroactive5test0yyAA1ZVy12RetroactiveB1XVSiAE1YVAG0D1A1PAAyHCg_AiJ1QAAyHCg1_GF ---> mangling_retroactive.test0(mangling_retroactive.Z<RetroactiveB.X, Swift.Int, RetroactiveB.Y>) -> ()
$s20mangling_retroactive5test0yyAA1ZVy12RetroactiveB1XVSiAE1YVAG0D1A1PHPyHCg_AiJ1QHPyHCg1_GF ---> mangling_retroactive.test0(mangling_retroactive.Z<RetroactiveB.X, Swift.Int, RetroactiveB.Y>) -> ()
$s20mangling_retroactive5test0yyAA1ZVy12RetroactiveB1XVSiAE1YVAG0D1A1PHpyHCg_AiJ1QHpyHCg1_GF ---> mangling_retroactive.test0(mangling_retroactive.Z<RetroactiveB.X, Swift.Int, RetroactiveB.Y>) -> ()
_T0LiteralAByxGxd_tcfC ---> _T0LiteralAByxGxd_tcfC
_T0XZ ---> _T0XZ
_TTSf0os___TFVs17_LegacyStringCore15_invariantCheckfT_T_ ---> function signature specialization <Arg[0] = Guaranteed To Owned and Exploded> of Swift._LegacyStringCore._invariantCheck() -> ()
_TTSf2o___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Guaranteed To Owned> of function signature specialization <Arg[0] = Exploded, Arg[1] = Dead> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TTSf2do___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Dead and Guaranteed To Owned> of function signature specialization <Arg[0] = Exploded, Arg[1] = Dead> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TTSf2dos___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> function signature specialization <Arg[0] = Dead and Guaranteed To Owned and Exploded> of function signature specialization <Arg[0] = Exploded, Arg[1] = Dead> of Swift._LegacyStringCore.init(Swift._StringBuffer) -> Swift._LegacyStringCore
_TTSf ---> _TTSf
_TtW0_j ---> _TtW0_j
_TtW_4m3a3v ---> _TtW_4m3a3v
_TVGVGSS_2v0 ---> _TVGVGSS_2v0
$SSD1BySSSBsg_G ---> $SSD1BySSSBsg_G
_Ttu4222222222222222222222222_rW_2T_2TJ_ ---> <A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, AB, BB, CB, DB, EB, FB, GB, HB, IB, JB, KB, LB, MB, NB, OB, PB, QB, RB, SB, TB, UB, VB, WB, XB, YB, ZB, AC, BC, CC, DC, EC, FC, GC, HC, IC, JC, KC, LC, MC, NC, OC, PC, QC, RC, SC, TC, UC, VC, WC, XC, YC, ZC, AD, BD, CD, DD, ED, FD, GD, HD, ID, JD, KD, LD, MD, ND, OD, PD, QD, RD, SD, TD, UD, VD, WD, XD, YD, ZD, AE, BE, CE, DE, EE, FE, GE, HE, IE, JE, KE, LE, ME, NE, OE, PE, QE, RE, SE, TE, UE, VE, WE, XE, ...> B.T_.TJ
_$S3BBBBf0602365061_ ---> _$S3BBBBf0602365061_
_$S3BBBBi0602365061_ ---> _$S3BBBBi0602365061_
_$S3BBBBv0602365061_ ---> _$S3BBBBv0602365061_
_T0lxxxmmmTk ---> _T0lxxxmmmTk
_TtCF4test11doNotCrash1FT_QuL_8MyClass1 ---> MyClass1 #1 in test.doNotCrash1() -> some
$s3Bar3FooVAA5DrinkVyxGs5Error_pSeRzSERzlyShy4AbcdAHO6MemberVGALSeHPAKSeAAyHC_HCg_ALSEHPAKSEAAyHC_HCg0_Iseggozo_SgWOe ---> outlined consume of (@escaping @callee_guaranteed @substituted <A where A: Swift.Decodable, A: Swift.Encodable> (@guaranteed Bar.Foo) -> (@owned Bar.Drink<A>, @error @owned Swift.Error) for <Swift.Set<Abcd.Abcd.Member>>)?
$s4Test5ProtoP8IteratorV10collectionAEy_qd__Gqd___tcfc ---> Test.Proto.Iterator.init(collection: A1) -> Test.Proto.Iterator<A1>
$s4test3fooV4blahyAA1SV1fQryFQOy_Qo_AHF ---> test.foo.blah(<<opaque return type of test.S.f() -> some>>.0) -> <<opaque return type of test.S.f() -> some>>.0
$S3nix8MystructV1xACyxGx_tcfc7MyaliasL_ayx__GD ---> Myalias #1 in nix.Mystruct<A>.init(x: A) -> nix.Mystruct<A>
$S3nix7MyclassCfd7MyaliasL_ayx__GD ---> Myalias #1 in nix.Myclass<A>.deinit
$S3nix8MystructVyS2icig7MyaliasL_ayx__GD ---> Myalias #1 in nix.Mystruct<A>.subscript.getter : (Swift.Int) -> Swift.Int
$S3nix8MystructV1x1uACyxGx_qd__tclufc7MyaliasL_ayx_qd___GD ---> Myalias #1 in nix.Mystruct<A>.<A1>(x: A, u: A1) -> nix.Mystruct<A>
$S3nix8MystructV6testit1xyx_tF7MyaliasL_ayx__GD ---> Myalias #1 in nix.Mystruct<A>.testit(x: A) -> ()
$S3nix8MystructV6testit1x1u1vyx_qd__qd_0_tr0_lF7MyaliasL_ayx_qd__qd_0__GD ---> Myalias #1 in nix.Mystruct<A>.testit<A1, B1>(x: A, u: A1, v: B1) -> ()
$S4blah8PatatinoaySiGD ---> blah.Patatino<Swift.Int>
$SSiSHsWP ---> protocol witness table for Swift.Int : Swift.Hashable in Swift
$S7TestMod5OuterV3Fooayx_SiGD ---> TestMod.Outer<A>.Foo<Swift.Int>
$Ss17_VariantSetBufferO05CocoaC0ayx_GD ---> Swift._VariantSetBuffer<A>.CocoaBuffer
$S2t21QP22ProtocolTypeAliasThingayAA4BlahV5SomeQa_GSgD ---> t2.Blah.SomeQ as t2.Q.ProtocolTypeAliasThing?
$s1A1gyyxlFx_qd__t_Ti5 ---> inlined generic function <(A, A1)> of A.g<A>(A) -> ()
$S1T19protocol_resilience17ResilientProtocolPTl ---> associated type descriptor for protocol_resilience.ResilientProtocol.T
$S18resilient_protocol21ResilientBaseProtocolTL ---> protocol requirements base descriptor for resilient_protocol.ResilientBaseProtocol
$S1t1PP10AssocType2_AA1QTn ---> associated conformance descriptor for t.P.AssocType2: t.Q
$S1t1PP10AssocType2_AA1QTN ---> default associated conformance accessor for t.P.AssocType2: t.Q
$s4Test6testityyxlFAA8MystructV_TB5 ---> generic specialization <Test.Mystruct> of Test.testit<A>(A) -> ()
$sSD5IndexVy__GD ---> $sSD5IndexVy__GD
$s4test3StrCACycfC ---> {T:$s4test3StrCACycfc} test.Str.__allocating_init() -> test.Str
$s18keypaths_inlinable13KeypathStructV8computedSSvpACTKq  ---> key path getter for keypaths_inlinable.KeypathStruct.computed : Swift.String : keypaths_inlinable.KeypathStruct, serialized
$s18resilient_protocol24ResilientDerivedProtocolPxAA0c4BaseE0Tn --> associated conformance descriptor for resilient_protocol.ResilientDerivedProtocol.A: resilient_protocol.ResilientBaseProtocol
$s3red4testyAA3ResOyxSayq_GAEs5ErrorAAq_sAFHD1__HCg_GADyxq_GsAFR_r0_lF ---> red.test<A, B where B: Swift.Error>(red.Res<A, B>) -> red.Res<A, [B]>
$s3red4testyAA7OurTypeOy4them05TheirD0Vy5AssocQzGAjE0F8ProtocolAAxAA0c7DerivedH0HD1_AA0c4BaseH0HI1_AieKHA2__HCg_GxmAaLRzlF ---> red.test<A where A: red.OurDerivedProtocol>(A.Type) -> red.OurType<them.TheirType<A.Assoc>>
$s17property_wrappers10WithTuplesV9fractionsSd_S2dtvpfP ---> property wrapper backing initializer of property_wrappers.WithTuples.fractions : (Swift.Double, Swift.Double, Swift.Double)
$sSo17OS_dispatch_queueC4sync7executeyyyXE_tFTOTA ---> {T:$sSo17OS_dispatch_queueC4sync7executeyyyXE_tFTO} partial apply forwarder for @nonobjc __C.OS_dispatch_queue.sync(execute: () -> ()) -> ()
$s4main1gyySiXCvp ---> main.g : @convention(c) (Swift.Int) -> ()
$s4main1gyySiXBvp ---> main.g : @convention(block) (Swift.Int) -> ()
$sxq_Ifgnr_D ---> @differentiable(_forward) @callee_guaranteed (@in_guaranteed A) -> (@out B)
$sxq_Irgnr_D ---> @differentiable(reverse) @callee_guaranteed (@in_guaranteed A) -> (@out B)
$sxq_Idgnr_D ---> @differentiable @callee_guaranteed (@in_guaranteed A) -> (@out B)
$sxq_Ilgnr_D ---> @differentiable(_linear) @callee_guaranteed (@in_guaranteed A) -> (@out B)
$sS3fIedgyywd_D ---> @escaping @differentiable @callee_guaranteed (@unowned Swift.Float, @unowned @noDerivative Swift.Float) -> (@unowned Swift.Float)
$sS5fIertyyywddw_D ---> @escaping @differentiable(reverse) @convention(thin) (@unowned Swift.Float, @unowned Swift.Float, @unowned @noDerivative Swift.Float) -> (@unowned Swift.Float, @unowned @noDerivative Swift.Float)
$syQo ---> $syQo
$s0059xxxxxxxxxxxxxxx_ttttttttBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBee -> $s0059xxxxxxxxxxxxxxx_ttttttttBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBee
$sx1td_t ---> (t: A...)
$s7example1fyyYaF -> example.f() async -> ()
$s7example1fyyYaKF -> example.f() async throws -> ()
//$s7example1fyyYjfYaKF -> example.f@differentiable(_forward) () async throws -> ()
//$s7example1fyyYjrYaKF -> example.f@differentiable(reverse) () async throws -> ()
//$s7example1fyyYjdYaKF -> example.f@differentiable () async throws -> ()
//$s7example1fyyYjlYaKF -> example.f@differentiable(_linear) () async throws -> ()
$s4main20receiveInstantiationyySo34__CxxTemplateInst12MagicWrapperIiEVzF ---> main.receiveInstantiation(inout __C.__CxxTemplateInst12MagicWrapperIiE) -> ()
$s4main19returnInstantiationSo34__CxxTemplateInst12MagicWrapperIiEVyF ---> main.returnInstantiation() -> __C.__CxxTemplateInst12MagicWrapperIiE
$s4main6testityyYaFTu ---> async function pointer to main.testit() async -> ()
$s13test_mangling3fooyS2f_S2ftFTJfUSSpSr ---> forward-mode derivative of test_mangling.foo(Swift.Float, Swift.Float, Swift.Float) -> Swift.Float with respect to parameters {1, 2} and results {0}
$s13test_mangling4foo21xq_x_t16_Differentiation14DifferentiableR_AA1P13TangentVectorRp_r0_lFAdERzAdER_AafGRpzAafHRQr0_lTJrSpSr ---> reverse-mode derivative of test_mangling.foo2<A, B where B: _Differentiation.Differentiable, B.TangentVector: test_mangling.P>(x: A) -> B with respect to parameters {0} and results {0} with <A, B where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable, A.TangentVector: test_mangling.P, B.TangentVector: test_mangling.P>
$s13test_mangling4foo21xq_x_t16_Differentiation14DifferentiableR_AA1P13TangentVectorRp_r0_lFAdERzAdER_AafGRpzAafHRQr0_lTJVrSpSr ---> vtable thunk for reverse-mode derivative of test_mangling.foo2<A, B where B: _Differentiation.Differentiable, B.TangentVector: test_mangling.P>(x: A) -> B with respect to parameters {0} and results {0} with <A, B where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable, A.TangentVector: test_mangling.P, B.TangentVector: test_mangling.P>
$s13test_mangling3fooyS2f_xq_t16_Differentiation14DifferentiableR_r0_lFAcDRzAcDR_r0_lTJpUSSpSr ---> pullback of test_mangling.foo<A, B where B: _Differentiation.Differentiable>(Swift.Float, A, B) -> Swift.Float with respect to parameters {1, 2} and results {0} with <A, B where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable>
$s13test_mangling4foo21xq_x_t16_Differentiation14DifferentiableR_AA1P13TangentVectorRp_r0_lFTSAdERzAdER_AafGRpzAafHRQr0_lTJrSpSr ---> reverse-mode derivative of protocol self-conformance witness for test_mangling.foo2<A, B where B: _Differentiation.Differentiable, B.TangentVector: test_mangling.P>(x: A) -> B with respect to parameters {0} and results {0} with <A, B where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable, A.TangentVector: test_mangling.P, B.TangentVector: test_mangling.P>
$s13test_mangling3fooyS2f_xq_t16_Differentiation14DifferentiableR_r0_lFAcDRzAcDR_r0_lTJpUSSpSrTj ---> dispatch thunk of pullback of test_mangling.foo<A, B where B: _Differentiation.Differentiable>(Swift.Float, A, B) -> Swift.Float with respect to parameters {1, 2} and results {0} with <A, B where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable>
$s13test_mangling3fooyS2f_xq_t16_Differentiation14DifferentiableR_r0_lFAcDRzAcDR_r0_lTJpUSSpSrTq ---> method descriptor for pullback of test_mangling.foo<A, B where B: _Differentiation.Differentiable>(Swift.Float, A, B) -> Swift.Float with respect to parameters {1, 2} and results {0} with <A, B where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable>
$s13TangentVector16_Differentiation14DifferentiablePQzAaDQy_SdAFIegnnnr_TJSdSSSpSrSUSP ---> autodiff subset parameters thunk for differential from @escaping @callee_guaranteed (@in_guaranteed A._Differentiation.Differentiable.TangentVector, @in_guaranteed B._Differentiation.Differentiable.TangentVector, @in_guaranteed Swift.Double) -> (@out B._Differentiation.Differentiable.TangentVector) with respect to parameters {0, 1, 2} and results {0} to parameters {0, 2}
$s13TangentVector16_Differentiation14DifferentiablePQy_AaDQzAESdIegnrrr_TJSpSSSpSrSUSP ---> autodiff subset parameters thunk for pullback from @escaping @callee_guaranteed (@in_guaranteed B._Differentiation.Differentiable.TangentVector) -> (@out A._Differentiation.Differentiable.TangentVector, @out B._Differentiation.Differentiable.TangentVector, @out Swift.Double) with respect to parameters {0, 1, 2} and results {0} to parameters {0, 2}
$s39differentiation_subset_parameters_thunk19inoutIndirectCalleryq_x_q_q0_t16_Differentiation14DifferentiableRzAcDR_AcDR0_r1_lFxq_Sdq_xq_Sdr0_ly13TangentVectorAcDPQy_AeFQzIsegnrr_Iegnnnro_TJSrSSSpSrSUSP ---> autodiff subset parameters thunk for reverse-mode derivative from differentiation_subset_parameters_thunk.inoutIndirectCaller<A, B, C where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable, C: _Differentiation.Differentiable>(A, B, C) -> B with respect to parameters {0, 1, 2} and results {0} to parameters {0, 2} of type @escaping @callee_guaranteed (@in_guaranteed A, @in_guaranteed B, @in_guaranteed Swift.Double) -> (@out B, @owned @escaping @callee_guaranteed @substituted <A, B> (@in_guaranteed A) -> (@out B, @out Swift.Double) for <B._Differentiation.Differentiable.TangentVectorA._Differentiation.Differentiable.TangentVector>)
$sS2f8mangling3FooV13TangentVectorVIegydd_SfAESfIegydd_TJOp ---> autodiff self-reordering reabstraction thunk for pullback from @escaping @callee_guaranteed (@unowned Swift.Float) -> (@unowned Swift.Float, @unowned mangling.Foo.TangentVector) to @escaping @callee_guaranteed (@unowned Swift.Float) -> (@unowned mangling.Foo.TangentVector, @unowned Swift.Float)
$s13test_mangling3fooyS2f_S2ftFWJrSpSr ---> reverse-mode differentiability witness for test_mangling.foo(Swift.Float, Swift.Float, Swift.Float) -> Swift.Float with respect to parameters {0} and results {0}
$s13test_mangling3fooyS2f_xq_t16_Differentiation14DifferentiableR_r0_lFAcDRzAcDR_r0_lWJrUSSpSr ---> reverse-mode differentiability witness for test_mangling.foo<A, B where B: _Differentiation.Differentiable>(Swift.Float, A, B) -> Swift.Float with respect to parameters {1, 2} and results {0} with <A, B where A: _Differentiation.Differentiable, B: _Differentiation.Differentiable>
$s5async1hyyS2iYbXEF ---> async.h(@Sendable (Swift.Int) -> Swift.Int) -> ()
$s5Actor02MyA0C17testAsyncFunctionyyYaKFTY0_ ---> (1) suspend resume partial function for Actor.MyActor.testAsyncFunction() async throws -> ()
$s5Actor02MyA0C17testAsyncFunctionyyYaKFTQ1_ ---> (2) await resume partial function for Actor.MyActor.testAsyncFunction() async throws -> ()
$s4diff1hyyS2iYjfXEF ---> diff.h(@differentiable(_forward) (Swift.Int) -> Swift.Int) -> ()
$s4diff1hyyS2iYjrXEF ---> diff.h(@differentiable(reverse) (Swift.Int) -> Swift.Int) -> ()
$s4diff1hyyS2iYjdXEF ---> diff.h(@differentiable (Swift.Int) -> Swift.Int) -> ()
$s4diff1hyyS2iYjlXEF ---> diff.h(@differentiable(_linear) (Swift.Int) -> Swift.Int) -> ()
$s4test3fooyyS2f_SfYkztYjrXEF ---> test.foo(@differentiable(reverse) (Swift.Float, inout @noDerivative Swift.Float) -> Swift.Float) -> ()
$s4test3fooyyS2f_SfYkntYjrXEF ---> test.foo(@differentiable(reverse) (Swift.Float, __owned @noDerivative Swift.Float) -> Swift.Float) -> ()
$s4test3fooyyS2f_SfYktYjrXEF ---> test.foo(@differentiable(reverse) (Swift.Float, @noDerivative Swift.Float) -> Swift.Float) -> ()
$s4test3fooyyS2f_SfYktYaYbYjrXEF ---> test.foo(@differentiable(reverse) @Sendable (Swift.Float, @noDerivative Swift.Float) async -> Swift.Float) -> ()
$sScA ---> Swift.Actor
$sScGySiG ---> Swift.TaskGroup<Swift.Int>
$s4test10returnsOptyxycSgxyScMYccSglF ---> test.returnsOpt<A>((@Swift.MainActor () -> A)?) -> (() -> A)?
$sSvSgA3ASbIetCyyd_SgSbIetCyyyd_SgD ---> (@escaping @convention(thin) @convention(c) (@unowned Swift.UnsafeMutableRawPointer?, @unowned Swift.UnsafeMutableRawPointer?, @unowned (@escaping @convention(thin) @convention(c) (@unowned Swift.UnsafeMutableRawPointer?, @unowned Swift.UnsafeMutableRawPointer?) -> (@unowned Swift.Bool))?) -> (@unowned Swift.Bool))?
$s4test10returnsOptyxycSgxyScMYccSglF ---> test.returnsOpt<A>((@Swift.MainActor () -> A)?) -> (() -> A)?
//$s1t10globalFuncyyAA7MyActorCYiF ---> t.globalFunc(isolated t.MyActor) -> ()
"""
    
    let simplified_mangles: String = """
_TtBf80_ ---> Builtin.FPIEEE80
_TtBi32_ ---> Builtin.Int32
_TtBw ---> Builtin.Word
_TtBO ---> Builtin.UnknownObject
_TtBo ---> Builtin.NativeObject
_TtBp ---> Builtin.RawPointer
_TtBv4Bi8_ ---> Builtin.Vec4xInt8
_TtBv4Bf16_ ---> Builtin.Vec4xFloat16
_TtBv4Bp ---> Builtin.Vec4xRawPointer
_TtSa ---> Array
_TtSb ---> Bool
_TtSc ---> UnicodeScalar
_TtSd ---> Double
_TtSf ---> Float
_TtSi ---> Int
_TtSq ---> Optional
_TtSS ---> String
_TtSu ---> UInt
_TtGSPSi_ ---> UnsafePointer<Int>
_TtGSpSi_ ---> UnsafeMutablePointer<Int>
_TtSV ---> UnsafeRawPointer
_TtSv ---> UnsafeMutableRawPointer
_TtGSaSS_ ---> [String]
_TtGSqSS_ ---> String?
_TtGSQSS_ ---> String!
_TtGVs10DictionarySSSi_ ---> [String : Int]
_TtVs7CString ---> CString
_TtCSo8NSObject ---> NSObject
_TtO6Monads6Either ---> Either
_TtbSiSu ---> @convention(block) (_:)
_TtcSiSu ---> @convention(c) (_:)
_TtbTSiSc_Su ---> @convention(block) (_:_:)
_TtcTSiSc_Su ---> @convention(c) (_:_:)
_TtFSiSu ---> (_:)
_TtKSiSu ---> @autoclosure (_:)
_TtFSiFScSu ---> (_:)
_TtMSi ---> Int.Type
_TtP_ ---> Any
_TtP3foo3bar_ ---> bar
_TtP3foo3barS_3bas_ ---> bar & bas
_TtTP3foo3barS_3bas_PS1__PS1_S_3zimS0___ ---> (bar & bas, bas, bas & zim & bar)
_TtRSi ---> inout Int
_TtTSiSu_ ---> (Int, UInt)
_TttSiSu_ ---> (Int, UInt...)
_TtT3fooSi3barSu_ ---> (foo: Int, bar: UInt)
_TturFxx ---> <A>(_:)
_TtuzrFT_T_ ---> <>()
_Ttu__rFxqd__ ---> <A><A1>(_:)
_Ttu_z_rFxqd0__ ---> <A><><A2>(_:)
_Ttu0_rFxq_ ---> <A, B>(_:)
_TtuR_s8RunciblerFxwx5Mince ---> <A>(_:)
_TtuR_Cs22AbstractRuncingFactoryrFxx ---> <A>(_:)
_TtuR_s8Runciblew_5MincezxrFxx ---> <A>(_:)
_Tv3foo3barSi ---> bar
_TF3fooau3barSi ---> bar.unsafeMutableAddressor
_TF3foolu3barSi ---> bar.unsafeAddressor
_TF3fooaO3barSi ---> bar.owningMutableAddressor
_TF3foolO3barSi ---> bar.owningAddressor
_TF3fooao3barSi ---> bar.nativeOwningMutableAddressor
_TF3foolo3barSi ---> bar.nativeOwningAddressor
_TF3fooap3barSi ---> bar.nativePinningMutableAddressor
_TF3foolp3barSi ---> bar.nativePinningAddressor
_TF3foog3barSi ---> bar.getter
_TF3foos3barSi ---> bar.setter
_TFC3foo3bar3basfT3zimCS_3zim_T_ ---> bar.bas(zim:)
_TToFC3foo3bar3basfT3zimCS_3zim_T_ ---> @objc bar.bas(zim:)
_TTDFC3foo3bar3basfT3zimCS_3zim_T_ ---> dynamic bar.bas(zim:)
_TFC3foo3bar3basfT3zimCS_3zim_T_ ---> bar.bas(zim:)
_TF3foooi1pFTCS_3barVS_3bas_OS_3zim ---> + infix(_:_:)
_TF3foooP1xFTCS_3barVS_3bas_OS_3zim ---> ^ postfix(_:_:)
_TFC3foo3barCfT_S0_ ---> bar.__allocating_init()
_TFC3foo3barcfT_S0_ ---> bar.init()
_TFC3foo3barD ---> bar.__deallocating_deinit
_TFC3foo3bard ---> bar.deinit
_TMPC3foo3bar ---> generic type metadata pattern for bar
_TMnC3foo3bar ---> nominal type descriptor for bar
_TMmC3foo3bar ---> metaclass for bar
_TMC3foo3bar ---> type metadata for bar
_TwalC3foo3bar ---> allocateBuffer for bar
_TwcaC3foo3bar ---> assignWithCopy for bar
_TwtaC3foo3bar ---> assignWithTake for bar
_TwdeC3foo3bar ---> deallocateBuffer for bar
_TwxxC3foo3bar ---> destroy for bar
_TwXXC3foo3bar ---> destroyBuffer for bar
_TwCPC3foo3bar ---> initializeBufferWithCopyOfBuffer for bar
_TwCpC3foo3bar ---> initializeBufferWithCopy for bar
_TwcpC3foo3bar ---> initializeWithCopy for bar
_TwTKC3foo3bar ---> initializeBufferWithTakeOfBuffer for bar
_TwTkC3foo3bar ---> initializeBufferWithTake for bar
_TwtkC3foo3bar ---> initializeWithTake for bar
_TwprC3foo3bar ---> projectBuffer for bar
_TWVC3foo3bar ---> value witness table for bar
_TWvdvC3foo3bar3basSi ---> direct field offset for bar.bas
_TWvivC3foo3bar3basSi ---> indirect field offset for bar.bas
_TWPC3foo3barS_8barrables ---> protocol witness table for bar
_TWaC3foo3barS_8barrableS_ ---> protocol witness table accessor for bar
_TWlC3foo3barS0_S_8barrableS_ ---> lazy protocol witness table accessor for type bar and conformance bar
_TWLC3foo3barS0_S_8barrableS_ ---> lazy protocol witness table cache variable for type bar and conformance bar
_TWGC3foo3barS_8barrableS_ ---> generic protocol witness table for bar
_TWIC3foo3barS_8barrableS_ ---> instantiation function for generic protocol witness table for bar
_TFSCg5greenVSC5Color ---> green.getter
_TIF1t1fFT1iSi1sSS_T_A_ ---> default argument 0 of f(i:s:)
_TIF1t1fFT1iSi1sSS_T_A0_ ---> default argument 1 of f(i:s:)
_TFSqcfT_GSqx_ ---> Optional.init()
_TF21class_bound_protocols32class_bound_protocol_compositionFT1xPS_10ClassBoundS_13NotClassBound__PS0_S1__ ---> class_bound_protocol_composition(x:)
_TtZZ ---> _TtZZ
_TtB ---> _TtB
_TtBSi ---> _TtBSi
_TtBx ---> _TtBx
_TtC ---> _TtC
_TtT ---> _TtT
_TtTSi ---> _TtTSi
_TtQd_ ---> _TtQd_
_Tw ---> _Tw
_TWa ---> _TWa
_Twal ---> _Twal
_T ---> _T
_TTo ---> _TTo
_TC ---> _TC
_TM ---> _TM
_TM ---> _TM
_TW ---> _TW
_TWV ---> _TWV
_TWo ---> _TWo
_TWv ---> _TWv
_TWvd ---> _TWvd
_TWvi ---> _TWvi
_TWvx ---> _TWvx
_TtVCC4main3Foo4Ding3Str ---> Foo.Ding.Str
_TFVCC6nested6AClass12AnotherClass7AStruct9aFunctionfT1aSi_S2_ ---> AClass.AnotherClass.AStruct.aFunction(a:)
_TtXwC10attributes10SwiftClass ---> weak SwiftClass
_TtXoC10attributes10SwiftClass ---> unowned SwiftClass
_TtERR ---> <ERROR TYPE>
_TtGSqGSaC5sugar7MyClass__ ---> [MyClass]?
_TtGSaGSqC5sugar7MyClass__ ---> [MyClass?]
_TtaC9typealias5DWARF9DIEOffset ---> DWARF.DIEOffset
_Ttas3Int ---> Int
_TTRXFo_dSc_dSb_XFo_iSc_iSb_ ---> thunk for @callee_owned (@in UnicodeScalar) -> (@out Bool)
_TTRXFo_dSi_dGSqSi__XFo_iSi_iGSqSi__ ---> thunk for @callee_owned (@in Int) -> (@out Int?)
_TTRGrXFo_iV18switch_abstraction1A_ix_XFo_dS0__ix_ ---> thunk for @callee_owned (@unowned A) -> (@out A)
_TFCF5types1gFT1bSb_T_L0_10Collection3zimfT_T_ ---> zim() in Collection #2 in g(b:)
_TFF17capture_promotion22test_capture_promotionFT_FT_SiU_FT_Si_promote0 ---> closure #1 in test_capture_promotion()
_TFIVs8_Processi10_argumentsGSaSS_U_FT_GSaSS_ ---> _arguments in variable initialization expression of _Process
_TFIvVs8_Process10_argumentsGSaSS_iU_FT_GSaSS_ ---> closure #1 in variable initialization expression of _Process._arguments
_TFCSo1AE ---> A.__ivar_destroyer
_TFCSo1Ae ---> A.__ivar_initializer
_TTWC13call_protocol1CS_1PS_FS1_3foofT_Si ---> protocol witness for P.foo() in conformance C
_TTSg5Si___TFSqcfT_GSqx_ ---> specialized Optional.init()
_TTSg5SiSis3Foos_Sf___TFSqcfT_GSqx_ ---> specialized Optional.init()
_TTSg5Si_Sf___TFSqcfT_GSqx_ ---> specialized Optional.init()
_TTSg5Si_Sf___TFSqcfT_GSqx_ ---> specialized Optional.init()
_TTSgS ---> _TTSgS
_TTSg5S ---> _TTSg5S
_TTSgSi ---> _TTSgSi
_TTSg5Si ---> _TTSg5Si
_TTSgSi_ ---> _TTSgSi_
_TTSgSi__ ---> _TTSgSi__
_TTSgSiS_ ---> _TTSgSiS_
_TTSgSi__xyz ---> _TTSgSi__xyz
_TTSg5Si___TTSg5Si___TFSqcfT_GSqx_ ---> specialized Optional.init()
_TTSg5Vs5UInt8___TFV10specialize3XXXcfT1tx_GS0_x_ ---> specialized XXX.init(t:)
_TPA__TTRXFo_oSSoSS_dSb_XFo_iSSiSS_dSb_31 ---> partial apply for thunk for @callee_owned (@in String, @in String) -> (@unowned Bool)
_TiC4Meow5MyCls9subscriptFT1iSi_Sf ---> MyCls.subscript(i:)
_TF8manglingX22egbpdajGbuEbxfgehfvwxnFT_T_ ---> ليهمابتكلموشعربي؟()
_TF8manglingX24ihqwcrbEcvIaIdqgAFGpqjyeFT_T_ ---> 他们为什么不说中文()
_TF8manglingX27ihqwctvzcJBfGFJdrssDxIboAybFT_T_ ---> 他們爲什麽不說中文()
_TF8manglingX30Proprostnemluvesky_uybCEdmaEBaFT_T_ ---> Pročprostěnemluvíčesky()
_TF8manglingXoi7p_qcaDcFTSiSi_Si ---> «+» infix(_:_:)
_TF8manglingoi2qqFTSiSi_T_ ---> ?? infix(_:_:)
_TFE11ext_structAV11def_structA1A4testfT_T_ ---> A.test()
_TF13devirt_accessP5_DISC15getPrivateClassFT_CS_P5_DISC12PrivateClass ---> getPrivateClass()
_TF4mainP5_mainX3wxaFT_T_ ---> λ()
_TF4mainP5_main3abcFT_aS_P5_DISC3xyz ---> abc()
_TtPMP_ ---> Any.Type
_TFCs13_NSSwiftArray29canStoreElementsOfDynamicTypefPMP_Sb ---> _NSSwiftArray.canStoreElementsOfDynamicType(_:)
_TFCs13_NSSwiftArrayg17staticElementTypePMP_ ---> _NSSwiftArray.staticElementType.getter
_TFCs17_DictionaryMirrorg9valueTypePMP_ ---> _DictionaryMirror.valueType.getter
_TPA__TFFVs11GeneratorOfcuRd__s13GeneratorTyperFqd__GS_x_U_FT_GSqx_ ---> partial apply for closure #1 in GeneratorOf.init<A>(_:)
_TTSf1cl35_TFF7specgen6callerFSiT_U_FTSiSi_T_Si___TF7specgen12take_closureFFTSiSi_T_T_ ---> specialized take_closure(_:)
_TTSf1cl35_TFF7specgen6callerFSiT_U_FTSiSi_T_Si___TTSg5Si___TF7specgen12take_closureFFTSiSi_T_T_ ---> specialized take_closure(_:)
_TTSg5Si___TTSf1cl35_TFF7specgen6callerFSiT_U_FTSiSi_T_Si___TF7specgen12take_closureFFTSiSi_T_T_ ---> specialized take_closure(_:)
_TTSf1cpfr24_TF8capturep6helperFSiT__n___TTRXFo_dSi_dT__XFo_iSi_dT__ ---> specialized thunk for @callee_owned (@in Int) -> (@unowned ())
_TTSf1cpfr24_TF8capturep6helperFSiT__n___TTRXFo_dSi_DT__XFo_iSi_DT__ ---> specialized thunk for @callee_owned (@in Int) -> (@unowned_inner_pointer ())
_TTSf1cpi0_cpfl0_cpse0v4u123_cpg53globalinit_33_06E7F1D906492AE070936A9B58CBAE1C_token8_cpfr36_TFtest_capture_propagation2_closure___TF7specgen12take_closureFFTSiSi_T_T_ ---> specialized take_closure(_:)
_TTSf0gs___TFVs17_LegacyStringCore15_invariantCheckfT_T_ ---> specialized _LegacyStringCore._invariantCheck()
_TTSf2g___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
_TTSf2dg___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
_TTSf2dgs___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
_TTSf3d_i_d_i_d_i___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
_TTSf3d_i_n_i_d_i___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
_TFIZvV8mangling10HasVarInit5stateSbiu_KT_Sb ---> implicit closure #1 in variable initialization expression of static HasVarInit.state
_TFFV23interface_type_mangling18GenericTypeContext23closureInGenericContexturFqd__T_L_3fooFTqd__x_T_ ---> foo #1 (_:_:) in GenericTypeContext.closureInGenericContext<A>(_:)
_TFFV23interface_type_mangling18GenericTypeContextg31closureInGenericPropertyContextxL_3fooFT_x ---> foo #1 () in GenericTypeContext.closureInGenericPropertyContext.getter
_TTWurGV23interface_type_mangling18GenericTypeContextx_S_18GenericWitnessTestS_FS1_23closureInGenericContextu_RxS1_rfqd__T_ ---> protocol witness for GenericWitnessTest.closureInGenericContext<A>(_:) in conformance <A> GenericTypeContext<A>
_TTWurGV23interface_type_mangling18GenericTypeContextx_S_18GenericWitnessTestS_FS1_g31closureInGenericPropertyContextwx3Tee ---> protocol witness for GenericWitnessTest.closureInGenericPropertyContext.getter in conformance <A> GenericTypeContext<A>
_TTWurGV23interface_type_mangling18GenericTypeContextx_S_18GenericWitnessTestS_FS1_16twoParamsAtDepthu0_RxS1_rfTqd__1yqd_0__T_ ---> protocol witness for GenericWitnessTest.twoParamsAtDepth<A, B>(_:y:) in conformance <A> GenericTypeContext<A>
_TFC3red11BaseClassEHcfzT1aSi_S0_ ---> BaseClassEH.init(a:)
_TFe27mangling_generic_extensionsR_S_8RunciblerVS_3Foog1aSi ---> Foo<A>.a.getter
_TFe27mangling_generic_extensionsR_S_8RunciblerVS_3Foog1bx ---> Foo<A>.b.getter
_TTRXFo_iT__iT_zoPs5Error__XFo__dT_zoPS___ ---> thunk for @callee_owned () -> (@unowned (), @error @owned Error)
_TFE1a ---> _TFE1a
_TFC4testP33_83378C430F65473055F1BD53F3ADCDB71C5doFoofT_T_ ---> C.doFoo()
_TTRXFo_oCSo13SKPhysicsBodydVSC7CGPointdVSC8CGVectordGSpV10ObjectiveC8ObjCBool___XFdCb_dS_dS0_dS1_dGSpS3____ ---> thunk for @callee_unowned @convention(block) (@unowned SKPhysicsBody, @unowned CGPoint, @unowned CGVector, @unowned UnsafeMutablePointer<ObjCBool>) -> ()
_T0So13SKPhysicsBodyCSC7CGPointVSC8CGVectorVSpy10ObjectiveC8ObjCBoolVGIxxyyy_AbdFSpyAIGIyByyyy_TR ---> thunk for @callee_owned (@owned SKPhysicsBody, @unowned CGPoint, @unowned CGVector, @unowned UnsafeMutablePointer<ObjCBool>) -> ()
_T04main1_yyF ---> _()
_T03abc6testitySiFTm ---> testit(_:)
_T04main4TestCACSi1x_tc6_PRIV_Llfc ---> Test.init(x:)
_$S3abc6testityySiFTm ---> testit(_:)
_$S4main4TestC1xACSi_tc6_PRIV_Llfc ---> Test.init(x:)
_TTSf0os___TFVs17_LegacyStringCore15_invariantCheckfT_T_ ---> specialized _LegacyStringCore._invariantCheck()
_TTSf2o___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
_TTSf2do___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
_TTSf2dos___TTSf2s_d___TFVs17_LegacyStringCoreCfVs13_StringBufferS_ ---> specialized _LegacyStringCore.init(_:)
"""
}
