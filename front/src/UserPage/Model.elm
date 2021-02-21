module UserPage.Model exposing (..)

import Json.Decode as D
import Http


type alias UserPageModel =
    { user : Maybe (Result Http.Error User)
    , blockPanel : List BlockAddress
    }


type alias User =
    { id: Int
    , username: String
    , email: String
    , block: List BlockAddress
    }


type BlockId
    = Id Int
    | New Int


type alias BlockAddress =
    { id : BlockId
    , url : String
    , start : String
    , end : String
    , active : Bool
    }


-- INIT

initUserPageModel : UserPageModel
initUserPageModel =
    UserPageModel
        Nothing
        []


newBlockAddress : Int -> BlockAddress
newBlockAddress tempId =
    BlockAddress (New tempId) "" "5" "10" True


-- Decoder

userDecoder : D.Decoder User
userDecoder =
    D.map4 User
        (D.field "id" D.int)
        (D.field "username" D.string)
        (D.field "email" D.string)
        (D.field "blocklist" (D.list blockAddressDecoder))


blockAddressDecoder : D.Decoder BlockAddress
blockAddressDecoder =
    D.map5 BlockAddress
        (D.field "id" (D.map (Id) D.int))
        (D.field "url" D.string)
        (D.field "start" (D.map String.fromInt D.int))
        (D.field "end" (D.map String.fromInt D.int))
        (D.field "active" D.bool)
