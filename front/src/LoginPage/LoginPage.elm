module LoginPage.LoginPage exposing (..)

import LoginPage.Model exposing (..)
import Http


type InputEvent
    = Email String
    | Password String
    | Remember Bool
    | SubmitForm


type LoginPageMsg
    = FormInput InputEvent
    | GotLoginResult (Result Http.Error ())



update : LoginPageMsg -> LoginPageModel ->  ( LoginPageModel, Cmd LoginPageMsg )
update msg model =
    case msg of
        FormInput event ->
            case event of
                Email e ->
                    ( { model | email = e }
                    , Cmd.none 
                    )
                
                Password p ->
                    ( { model | password = p }
                    , Cmd.none
                    )
                
                Remember b ->
                    ( { model | remember = b }
                    , Cmd.none
                    )
                
                SubmitForm ->
                    ( model, loginRequest model )

        GotLoginResult result ->
            ( { model | result = Just result }
            , Cmd.none
            )

-- CMD

loginRequest : LoginPageModel -> Cmd LoginPageMsg
loginRequest model =
    Http.post
        { url = "/api/user/login"
        , body = Http.jsonBody <| loginModelEncoder model
        , expect = Http.expectWhatever GotLoginResult
        }
