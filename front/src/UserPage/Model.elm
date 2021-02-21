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


type alias BlockAddress =
    { id : Int
    , url : String
    , start : Int
    , end : Int
    , active : Bool
    }


-- INIT

initUserPageModel : UserPageModel
initUserPageModel =
    UserPageModel
        Nothing
        []


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
        (D.field "id" D.int)
        (D.field "url" D.string)
        (D.field "start" D.int)
        (D.field "end" D.int)
        (D.field "active" D.bool)
