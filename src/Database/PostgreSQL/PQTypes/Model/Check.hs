module Database.PostgreSQL.PQTypes.Model.Check (
    Check(..)
  , tblCheck
  , sqlAddCheck
  , sqlAddValidCheck
  , sqlAddNotValidCheck
  , sqlValidateCheck
  , sqlDropCheck
  ) where

import Data.Monoid.Utils
import Database.PostgreSQL.PQTypes
import Prelude

data Check = Check {
  chkName      :: RawSQL ()
, chkCondition :: RawSQL ()
, chkValidated :: Bool -- ^ Set to 'False' if check is created as NOT VALID and
                       -- not validated afterwards.
} deriving (Eq, Ord, Show)

tblCheck :: Check
tblCheck = Check
  { chkName      = ""
  , chkCondition = ""
  , chkValidated = True
  }

{-# DEPRECATED sqlAddCheck "Use sqlAddValidCheck instead" #-}
-- | Deprecated version of 'sqlAddValidCheck'.
sqlAddCheck :: Check -> RawSQL ()
sqlAddCheck = sqlAddCheck_ True

-- | Add valid check constraint. Warning: PostgreSQL acquires SHARE ROW
-- EXCLUSIVE lock (that prevents updates) on modified table for the duration of
-- the creation. If this is not acceptable, use 'sqlAddNotValidCheck' and
-- 'sqlValidateCheck'.
sqlAddValidCheck :: Check -> RawSQL ()
sqlAddValidCheck = sqlAddCheck_ True

-- | Add check marked as NOT VALID. This avoids potentially long validation
-- blocking updates to modified table for its duration. However, checks created
-- as such need to be validated later using 'sqlValidateCheck'.
sqlAddNotValidCheck :: Check -> RawSQL ()
sqlAddNotValidCheck = sqlAddCheck_ False

-- | Validate check previously created as NOT VALID.
sqlValidateCheck :: Check -> RawSQL ()
sqlValidateCheck Check{..} = "VALIDATE" <+> chkName

sqlAddCheck_ :: Bool -> Check -> RawSQL ()
sqlAddCheck_ valid Check{..} = smconcat [
    "ADD CONSTRAINT"
  , chkName
  , "CHECK ("
  , chkCondition
  , ")"
  , if valid then "" else " NOT VALID"
  ]

sqlDropCheck :: RawSQL () -> RawSQL ()
sqlDropCheck name = "DROP CONSTRAINT" <+> name
