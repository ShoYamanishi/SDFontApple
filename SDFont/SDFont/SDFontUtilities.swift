func roundUp16( _ v : Int ) -> Int {
    return (v + 15) / 16 * 16
}

func roundUp16( _ v : Int32 ) -> Int32 {
    return (v + 15) / 16 * 16
}

func clamp<T : Comparable >( low : T, val : T, high : T ) -> T {
    return max( low, min( high, val ) )
}
