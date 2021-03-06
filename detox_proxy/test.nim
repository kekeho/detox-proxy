import tables
import hashes


type
    A = object
        a: string
        b: string


proc hash(x: A): Hash =
    return hash(x.a)


var t = initTable[A, bool]()
let x = A(a: "hoge", b: "fuga")
let y = A(a: "hoge", b: "piyo")

t[x] = true
echo t[x]
echo t.hasKey(y)
echo t[y]



