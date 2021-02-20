module UserPage.UserPage exposing (..)

import Http
import UserPage.Model exposing (..)


type UserPageMsg
    = GetLoginUserInfo
    | GotLoginUserInfo (Result Http.Error User)



update : UserPageMsg -> UserPageModel -> (UserPageModel, Cmd UserPageMsg)
update msg model =
    case msg of
        GetLoginUserInfo ->
            ( model, getLoginUserInfo )
        
        GotLoginUserInfo result ->
            ( { model | user = Just result }
            , Cmd.none
            )
                



-- CMD

getLoginUserInfo : Cmd UserPageMsg
getLoginUserInfo =
    Http.get
        { url = "/api/user"
        , expect = Http.expectJson GotLoginUserInfo userDecoder
        }


