module UserPage.View exposing (..)

import UserPage.UserPage exposing (UserPageMsg)
import UserPage.Model exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


view : UserPageModel -> (String, List (Html UserPageMsg))
view model =
    ( "userpage"
    , [ blockListPanelView model
      ]
    )


blockListPanelView : UserPageModel -> Html UserPageMsg
blockListPanelView model =
    div [ class "blocklist panel" ]
        [ h1 [] [ text "ブロックリスト" ]
        , div [ class "blocklist-container" ]
            [ blockListView model ]
        ]


blockListView : UserPageModel -> Html UserPageMsg
blockListView model =
    table [ class "block-list" ]
        [ col [ class "active" ] []
        , col [ class "host" ] []
        , col [ class "start" ] []
        , col [ class "end" ] []
        , thead []
            [ tr [] 
                [ th [] [ text "ON" ]
                , th [] [ text "Host" ]
                , th [] [ text "遮断 [分]" ]
                , th [] [ text "再開 [分]" ]
                ]
            ]
        , tbody []
            <| List.map blockRowView model.blockPanel
        ]


blockRowView : BlockAddress -> Html UserPageMsg
blockRowView block =
    tr [ class "block-row" ]
        [ td [ class "active" ]
            [ input [ type_ "checkbox", checked block.active ] 
                [] 
            ]
        , td [ class "host" ]
            [ input [ type_ "url", value block.url ] [] ]
        , td [ class "start" ]
            [ input [ type_ "number", value <| String.fromInt block.start ] [] ]
        , td [ class "end" ]
            [ input [ type_ "number", value <| String.fromInt block.end ] [] ]
        ]
