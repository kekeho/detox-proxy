module UserPage.View exposing (..)

import UserPage.UserPage exposing (UserPageMsg)
import UserPage.Model exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


view : User -> UserPageModel -> (String, List (Html UserPageMsg))
view user model =
    ( "userpage"
    , [ blockListPanelView user model
      ]
    )


blockListPanelView : User -> UserPageModel -> Html UserPageMsg
blockListPanelView user model =
    div [ class "blocklist panel" ]
        [ h1 [] [ text "ブロックリスト" ]
        , blockListView user model
        ]


blockListView : User -> UserPageModel -> Html UserPageMsg
blockListView user model =
    table [ class "block-list" ]
        [ thead []
            [ tr [] 
                [ th [] [ text "Active" ]
                , th [] [ text "Host" ]
                , th [] [ text "遮断" ]
                , th [] [ text "再開" ]
                ] 
            ]

        , tbody []
            <| List.map blockRowView user.block
        ]


blockRowView : BlockAddress -> Html UserPageMsg
blockRowView block =
    tr [ class "block-row" ]
        [ td [ class "active" ]
            [ input [ type_ "checkbox", checked block.active ] 
                [] 
            ]
        , td [ class "host" ] [ text block.url ]
        , td [ class "start" ] [ text <| String.fromInt block.start]
        , td [ class "end" ] [ text <| String.fromInt block.end ]
        ]
