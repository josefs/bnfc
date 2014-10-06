{-
    BNF Converter: Template Generator
    Copyright (C) 2004  Author:  Markus Forberg

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-}


module BNFC.Backend.Haskell.CFtoTemplate (
		    cf2Template
                    ) where

import BNFC.CF
import Data.Char

type ModuleName = String
type Constructor = String

cf2Template :: ModuleName -> ModuleName -> ModuleName -> CF -> String
cf2Template skelName absName errName cf = unlines
  [
  "module "++ skelName ++ " where\n",
  "-- Haskell module generated by the BNF converter\n",
  "import " ++ absName,
  "import " ++ errName,
  "type Result = Err String\n",
  "failure :: Show a => a -> Result",
  "failure x = Bad $ \"Undefined case: \" ++ show x\n",
  unlines $ map (\(s,xs) -> case_fun s (toArgs xs)) $ specialData cf ++ cf2data cf
  ]
 where toArgs               [] = []
       toArgs ((cons,args):xs)
	   = (cons ++ " " ++  names False (map (checkRes . var) args) (1 :: Int)) : toArgs xs
       names _ [] _ = []
       names b (x:xs) n
        | elem x xs = (x ++ show n) ++ " " ++ names True xs (n+1)
	| otherwise = (x ++ if b then show n else "") ++ " " ++ names b xs (if b then n+1 else n)
{-
       toArgs ((cons,args):xs)
	   = (cons ++ " " ++  names (map (checkRes . var) args) (0 :: Int)) : toArgs xs
       names [] _ = []
       names (x:xs) n
        | elem x xs = (x ++ show n) ++ " " ++ names xs (n+1)
	| otherwise = x ++ " " ++ names xs n
-}
       var (ListCat c) = var c ++ "s"
       var (Cat "Ident")   = "id"
       var (Cat "Integer") = "n"
       var (Cat "String")  = "str"
       var (Cat "Char")    = "c"
       var (Cat "Double")  = "d"
       var xs        = map toLower (show xs)
       checkRes s
        | elem s reservedHaskell = s ++ "'"
	| otherwise              = s
       reservedHaskell =  ["case","class","data","default","deriving","do","else","if",
			   "import","in","infix","infixl","infixr","instance","let","module",
			   "newtype","of","then","type","where","as","qualified","hiding"]

{- ----
cf2Template :: ModuleName -> CF -> String
cf2Template name cf = unlines
  [
  "module Skel"++ name ++ " where\n",
  "-- Haskell module generated by the BNF converter\n",
  "import Abs" ++ name,
  "import ErrM",
  "type Result = Err String\n",
  "failure :: Show a => a -> Result",
  "failure x = Bad $ \"Undefined case: \" ++ show x\n",
  unlines $ map (\(s,xs) -> case_fun s (toArgs xs)) $ specialData cf ++ cf2data cf
  ]
 where toArgs               [] = []
       toArgs ((cons,args):xs)
	   = (cons ++ " " ++  names False (map (checkRes . var) args) (1 :: Int)) : toArgs xs
       names _ [] _ = []
       names b (x:xs) n
        | elem x xs = (x ++ show n) ++ " " ++ names True xs (n+1)
	| otherwise = (x ++ if b then show n else "") ++ " " ++ names b xs (if b then n+1 else n)
       var ('[':xs)  = var (init xs) ++ "s"
       var "Ident"   = "id"
       var "Integer" = "n"
       var "String"  = "str"
       var "Char"    = "c"
       var "Double"  = "d"
       var xs        = map toLower xs
       checkRes s
        | elem s reservedHaskell = s ++ "'"
	| otherwise              = s
       reservedHaskell = ["case","class","data","default","deriving","do","else","if",
			  "import","in","infix","infixl","infixr","instance","let","module",
			  "newtype","of","then","type","where","as","qualified","hiding"]
-}

case_fun :: Cat -> [Constructor] -> String
case_fun cat xs =
 unlines $
	 ["trans" ++ cat' ++ " :: " ++ cat' ++ " -> Result",
	  "trans" ++ cat' ++ " x = case x of",
	  unlines $ map (\s -> "  " ++ s ++ " -> " ++ "failure x") xs]
  where cat' = show cat
