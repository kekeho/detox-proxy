-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

module LoginPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http

import LoginPage.LoginPage exposing (..)
import LoginPage.Model exposing (LoginPageModel)


view: LoginPageModel -> (String, List (Html LoginPageMsg))
view model =
    ( "loginpage"
    , [ div [ class "login panel" ]
        [ h1 [] [ text "ログイン" ]
        , Html.form [ onSubmit <| FormInput (SubmitForm)]
            [ loginFieldView "email" "email" "メールアドレス" True
                model.email
                (onInput <| (\s -> FormInput (Email s)))
            , loginFieldView "password" "password" "パスワード" True
                model.password
                (onInput <| (\s -> FormInput (Password s)))
            , p [ ] 
                [ input
                    [ type_ "checkbox", id "remember"
                    , checked model.remember
                    , onCheck <| (\c -> FormInput (Remember c))
                    ]
                    []
                , label [ for "remember" ] [ text "ログインを記憶する"]
                ]
            , input
                [ type_ "submit", value "ログイン" ]
                []
            , errorView model.result
            ]
        ]
      ]
    )


loginFieldView : String -> String -> String -> Bool -> String -> Attribute LoginPageMsg -> Html LoginPageMsg
loginFieldView formId formType labelStr req val attr =
    div [ class "form-column" ]
        [ label [ for formId ] [ text labelStr ]
        , input [ type_ formType, id formId, required req, value val,attr ] []
        ]


errorView : Maybe (Result Http.Error ()) -> Html msg
errorView maybeResult =
    case maybeResult of
        Just (Err e) ->
            case e of
                Http.BadStatus 401 ->
                    p [ class "error" ]
                        [ text "メールアドレス、またはパスワードが間違っています" ]
                _ ->
                    p [ class "error" ]
                        [ text "不明なエラーが発生しました" ]
        _ ->
            p [] []
