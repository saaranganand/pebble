package projectile

Shape :: union #no_nil { Circle, Ray, Line }

Circle :: struct { radius: f32, }
Ray :: struct {}
Line :: struct { length: f32 }