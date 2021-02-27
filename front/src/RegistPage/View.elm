-- Copyright (c) 2021 Hiroki Takemura (kekeho)

-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

module RegistPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import RegistPage.RegistPage exposing (..)
import RegistPage.Model exposing (RegistPageModel)
import UserPage.Model exposing (User)
import Http


view: RegistPageModel -> (String, List (Html RegistPageMsg))
view model =
    ( "registpage"
    , registView model
    )


registView : RegistPageModel -> List (Html RegistPageMsg)
registView model =
    [ div [ class "regist panel" ]
        [ registPanelView model ]
    , introductionView
    ]


registPanelView : RegistPageModel -> Html RegistPageMsg
registPanelView model =
    div [ class "regist-panel" ]
        [ h1 [] [ text "ユーザー登録" ]
        , registFormView model
        ]


registFormView : RegistPageModel -> Html RegistPageMsg
registFormView model =
    Html.form [ onSubmit <| FormInput SubmitForm ]
        [ registFieldView "username" "text" "ユーザー名" 
            True model.username
            (onInput <| (\s -> FormInput (UserName s)))
        , registFieldView "email" "email" "メールアドレス"
            True model.email
            (onInput <| (\s -> FormInput (Email s)))
        , registFieldView "password" "password" "パスワード"
            True model.password
            (onInput <| (\s -> FormInput (Password s)))
        , confirmTeamOfServiceView model.teamOfServiceAccept
        , input [ type_ "submit", value "登録" ] []
        , errorView model.result
        ]


registFieldView : String -> String -> String -> Bool -> String -> Attribute msg -> Html msg
registFieldView formId formType labelStr req val attr =
    div [ class "form-column" ]
        [ label [ for formId ] [ text labelStr ]
        , input [ type_ formType, id formId, required req, value val,attr ] []
        ]


introductionView : Html RegistPageMsg
introductionView =
    div [ class "introduction panel flat" ]
        [ h1 [] 
            [ text "バランスの取れた デジタルライフへ" ]
        , introductionSection "登録は簡単"
            [ p []
                [ text "フォームに情報を入力して登録ボタンを押したら、メールで認証するだけ。" ]
            , p []
                [ text "すぐにアクセス制御を設定して、数分後には健康的な生活への第一歩を踏み出すことができます。" ]
            ]
        , introductionSection "ユーザーのプライバシーを保護"
            [ p []
                [ text "detox-proxyを使えば、接続先のWEBサービスに対し、ユーザーのIPアドレスなどの個人情報を隠すことができます。"]
            ]
        ]


introductionSection : String -> List (Html msg) -> Html msg
introductionSection sectionTitle contents =
    div [ class "intro-section" ]
        (h2 [] [ text sectionTitle ] :: contents)


confirmTeamOfServiceView : Bool -> Html RegistPageMsg
confirmTeamOfServiceView nowValue =
    p [ class "team-of-service" ] 
        [ input
            [ type_ "checkbox", id "teamofservice"
            , checked nowValue
            , required True
            , onCheck (\x -> FormInput (TeamOfService x))
            ]
            [ ]
        , label [ for "teamofservice" ] 
            [ a [ href "/docs/teamofservice", target "_blank" ]  [ text "利用規約" ]
            , text "に同意"
            ]
        ]


errorView : Maybe (Result Http.Error User) -> Html RegistPageMsg
errorView maybeResult =
    case maybeResult of
        Nothing ->
            p [] []
        Just (Ok _) ->
            p [] []
        
        Just (Err e) ->
            case e of
                Http.BadStatus 409 ->
                    p [ class "error" ]
                        [ text "すでにアカウントが登録されています" ]
                _ ->
                    p [ class "error" ]
                        [ text "不明なエラーが発生しました" ]

