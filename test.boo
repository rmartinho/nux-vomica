from System import Func
import Boo.Lang.Compiler.Ast

class Option[of T(class)]:
    final value as T = null
    final isSome = false

    def constructor():
        pass

    def constructor(initialValue as T):
        isSome = true
        value = initialValue

    IsSome as bool:
        get:
            return isSome

    Value as T:
        get:
            return value

    static def op_Implicit(n as None):
        return Option[of T]()

    # TODO op== and the rest

def some[of T(class)](t as T):
    return Option[of T](t)
def none[of T(class)]():
    return Option[of T]()
class None:
    pass
def none():
    return None()

class OptionEnv:
    def Return[of T(class)](t as T):
        return some(t)
    def Bind[of T(class), U(class)](m as Option[of T], f as Func[of T, Option[of U]]) as Option[of U]:
        if m.IsSome:
            return f(m.Value)
        else:
            return none()

option = OptionEnv()

macro env(e as Expression):
    static final letCall = ReferenceExpression()
    macro let(e as BinaryExpression):
        if e.Operator != BinaryOperatorType.Assign:
            raise System.Exception("must be assignment")
        return ExpressionStatement([| $letCall($e) |])

    return [| print $(AstUtil.ToXml(env.Body)) |]

foo = none[of string]() #some("foo")

env option:
    let x = foo
    return x + "bar"

print bar.IsSome

