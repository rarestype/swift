// swiftlang/llvm-project d7f258ad2a: an async function that keeps a 32-byte vector alive across
// an `await` gets a coroutine frame smaller than its fields, so the vector reads back as
// garbage. Prints `ok` once the frame is laid out correctly.
struct S {
    var a: Int, b: Int, c: Int, d: Int, e: Int
    var v: SIMD4<Int>
}

@inline(never) func make(_ x: Int) -> S {
    .init(a: x, b: x, c: x, d: x, e: x, v: .init(x, x, x, x))
}
@inline(never) func pause() async {}

@inline(never) func f(_ x: Int) async -> Int {
    let s: S = make(x)
    let v: SIMD4<Int> = s.v
    await pause()
    return s.a &+ s.b &+ s.c &+ s.d &+ s.e &+ v.wrappedSum()
}

@main enum Main {
    static func main() async {
        let result: Int = await f(1)
        print(result == 9 ? "ok" : "wrong: expected 9, got \(result)")
    }
}
