module RegistPage.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import RegistPage.RegistPage exposing (..)
import RegistPage.Model exposing (RegistPageModel)


view: RegistPageModel -> (String, List (Html RegistPageMsg))
view model =
    ( "registpage"
    , registView model
    )


registView : RegistPageModel -> List (Html RegistPageMsg)
registView model =
    [ div [ class "regist" ]
        [ registPanelView model ]
    , introductionView
    ]


registPanelView : RegistPageModel -> Html RegistPageMsg
registPanelView model =
    div [ class "regist-panel" ]
        [ h1 [] [ text "ユーザー登録" ]
        , case model.result of
            Just (Ok _) ->
                registeredView model
            _ ->
                registFormView model
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
        ]


registFieldView : String -> String -> String -> Bool -> String -> Attribute msg -> Html msg
registFieldView formId formType labelStr req val attr =
    div [ class "form-column" ]
        [ label [ for formId ] [ text labelStr ]
        , input [ type_ formType, id formId, required req, value val,attr ] []
        ]


introductionView : Html RegistPageMsg
introductionView =
    div [ class "introduction" ]
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
    let
        valueStr =
            if nowValue then "true"
            else "false"
    in
    p [ class "team-of-service" ] 
        [ input
            [ type_ "checkbox", id "teamofservice", value valueStr
            , required True
            , onCheck (\x -> FormInput (TeamOfService x))
            ]
            [ ]
        , label [ for "teamofservice" ] 
            [ a [ href "/docs/teamofservice", target "_blank" ]  [ text "利用規約" ]
            , text "に同意"
            ]
        ]


registeredView : RegistPageModel -> Html RegistPageMsg
registeredView model =
    div [ class "registered" ]
        [ h2 [ ]
            [ text "仮登録が完了しました👍" ]
        , p [] [ text "最後のステップです!" ]
        , p []
            [ text "メールアドレスに、認証用のリンクを送信しました。リンクをクリックして、アカウントを有効化してください。" ]
        , p []
            [ text "メールが届いていない場合は、迷惑フォルダを確認してみてください。" ]
        ]
