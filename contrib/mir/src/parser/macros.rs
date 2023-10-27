/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

#[cfg(test)]
mod tests {
    use crate::parser::parse;

    #[test]
    fn test_macros() {
        use crate::ast::Instruction::*;

        assert_eq!(
            parse("{ ASSERT }").unwrap(),
            vec![Seq(vec![If(vec![], vec![Unit, Failwith(())])])]
        );

        assert_eq!(
            parse("{ ASSERT_CMPEQ }").unwrap(),
            vec![Seq(vec![
                Seq(vec![Compare, Eq]),
                If(vec![], vec![Seq(vec![Unit, Failwith(())])])
            ])]
        );

        assert_eq!(
            parse("{ ASSERT_CMPLE }").unwrap(),
            vec![Seq(vec![
                Seq(vec![Compare, Le]),
                If(vec![], vec![Seq(vec![Unit, Failwith(())])])
            ])]
        );

        assert_eq!(
            parse("{ IF_SOME { UNIT } {} }").unwrap(),
            vec![Seq(vec![IfNone(vec![], vec![Unit])])]
        );

        assert_eq!(
            parse("{ IFCMPEQ { UNIT } {} }").unwrap(),
            vec![Seq(vec![Compare, Eq, If(vec![Unit], vec![])])]
        );

        assert_eq!(
            parse("{ IFCMPLE { UNIT } {} }").unwrap(),
            vec![Seq(vec![Compare, Le, If(vec![Unit], vec![])])]
        );

        assert_eq!(
            parse("{ DIIIP { UNIT } }").unwrap(),
            vec![Dip(Some(3), vec![Unit])]
        );

        assert_eq!(parse("{ DUUP }").unwrap(), vec![Dup(Some(2))]);

        assert_eq!(parse("{ DUUUUP }").unwrap(), vec![Dup(Some(4))]);

        assert_eq!(
            parse("{ FAIL }").unwrap(),
            vec![Seq(vec![Unit, Failwith(())])]
        );

        assert_eq!(
            parse("{ IF FAIL FAIL }").unwrap(),
            vec![If(vec![Unit, Failwith(())], vec![Unit, Failwith(())])]
        );

        assert_eq!(
            parse("{ IF DUUP DUUP }")
                .unwrap_err()
                .to_string()
                .lines()
                .next(),
            Some("Unrecognized token `DUUP` found at 5:9")
        );

        assert_eq!(
            parse("{ FAIL {} {} }")
                .unwrap_err()
                .to_string()
                .lines()
                .next(),
            Some("Unrecognized token `{` found at 7:8"),
        );
    }
}
