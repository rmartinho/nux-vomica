from System import Func
import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import System.Linq.Enumerable from System.Core

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
        return Option of T()

    # TODO op== and the rest

def some[of T(class)](t as T):
    return Option of T(t)
def none[of T(class)]():
    return Option of T()
class None:
    pass
def none():
    return None()

class OptionEnv:
    def Return[of T(class)](t as T):
        return some(t)
    def Bind[of T(class), U(class)](m as Option of T, f as Func[of T, Option of U]) as Option of U:
        if m.IsSome:
            return f(m.Value)
        else:
            return none()

option = OptionEnv()

macro env(builder as Expression):
    static final letRef = ReferenceExpression(CompilerContext.Current.GetUniqueName("let"))
    static final doRef = ReferenceExpression(CompilerContext.Current.GetUniqueName("do"))
    static final varRef = ReferenceExpression(CompilerContext.Current.GetUniqueName("var"))
    macro let_(action as Expression):
        return ExpressionStatement([| $doRef($action) |])
    macro let(binding as BinaryExpression):
        if binding.Operator != BinaryOperatorType.Assign:
            raise System.Exception("'let' must be followed by assignment")
        return ExpressionStatement([| $letRef($binding) |])

    TransformBlock = def(builder as ReferenceExpression, statements as Statement*) as Expression:
        return null

    def TransformLet(builder as ReferenceExpression, binding as BinaryExpression, rest as Statement*):
        var = binding.Left cast ReferenceExpression
        obj = binding.Right cast Expression
        body = TransformBlock(builder, rest)
        return [| $builder.Bind($obj, { $var | $body }) |]

    def TransformDo(builder as ReferenceExpression, action as Expression, rest as Statement*):
        body = TransformBlock(builder, rest)
        return [| $builder.Bind($action, { $varRef | $body }) |]

    def TransformReturn(builder as ReferenceExpression, expression as Expression, rest as Statement*):
        return [| $builder.Return($expression) |]

    def TransformBlockHead(builder as ReferenceExpression, head as Statement, tail as Statement*):
        match head:
            case ExpressionStatement( \
                    Expression: MethodInvocationExpression( \
                        Target: target = ReferenceExpression(), \
                        Arguments: (arg,))):
                match target.Name:
                    case letRef.Name:
                        return TransformLet(builder, arg cast BinaryExpression, tail)
                    case doRef.Name:
                        return TransformDo(builder, arg, tail)
            case ReturnStatement(Expression: exp):
                return TransformReturn(builder, exp, tail)
            otherwise:
                raise System.Exception("not supported!")

    TransformBlock = def(builder as ReferenceExpression, statements as Statement*):
        head = statements.First()
        tail = statements.Skip(1).ToList()
        return TransformBlockHead(builder, head, tail)

    #return [| print $(AstUtil.ToXml(TransformBlock(builder cast ReferenceExpression, env.Body.Statements))) |]
    return [| print $(TransformBlock(builder cast ReferenceExpression, env.Body.Statements).ToCodeString()) |]

foo = none[of string]() #some("foo")
bar = none[of string]() #some("bar")

env option:
    let x = foo
    let y = bar
    let_ f(x + y)
    return x + y

