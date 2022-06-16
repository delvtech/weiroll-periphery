//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Expressions {

    enum Operator {
        LE,   // Less than equal
        GE,   // Greator than equal
        EQ,   // Equal
        LT,   // Less than
        GT,   // Greator than,
        NE    // Not equal
    }

    enum Conjunction {
        AND,    // &&
        OR      // ||
    }

    struct Condition {
        uint256 leftOperand;
        uint256 rightOperand;
        Operator op;
    }

    struct Statement {
        Condition leftCondition;
        Condition rightCondition;
        Conjunction cj;
    }

    function calculateExpr(uint256 op1, uint256 op2, Operator op) internal pure returns(bool result) {
        if (op == Operator.LE) {
            return op1 == op2;
        } else if (op == Operator.GE) {
            return op1 >= op2;
        } else if (op == Operator.EQ) {
            return op1 == op2;
        } else if (op == Operator.LT) {
            return op1 < op2;
        } else if (op == Operator.GT) {
            return op1 > op2;
        } else if (op == Operator.NE) {
            return op1 != op2;
        }
    }

    function calculateExpr(bool expr1, bool expr2, Conjunction cj) internal pure returns(bool result) {
        if (cj == Conjunction.AND) {
            return expr1 && expr2;
        } else if (cj == Conjunction.OR) {
            return expr1 || expr2;
        }
    }

    function calculateLogicalStatement(Condition calldata cond1, Condition calldata cond2, Conjunction cj) internal pure returns(bool result) {
        return calculateExpr(resolveCondition(cond1), resolveCondition(cond2), cj);
    }

    function resolveCondition(Condition calldata cond) internal pure returns(bool result) {
        return calculateExpr(cond.leftOperand, cond.rightOperand, cond.op);
    } 

    function resolveStatement(Statement calldata stmt) internal pure returns(bool result) {
        return calculateLogicalStatement(stmt.leftCondition, stmt.leftCondition, stmt.cj);
    }

}