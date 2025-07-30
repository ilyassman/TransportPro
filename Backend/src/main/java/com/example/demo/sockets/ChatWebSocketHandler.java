package com.example.demo.sockets;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private static final List<WebSocketSession> sessions = new CopyOnWriteArrayList<>();
    private static final Map<Long, WebSocketSession> userSessions = new HashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.add(session);
        // Extraire l'ID utilisateur de l'URL ou des paramètres
        String userId = extractUserIdFromSession(session);
        if (userId != null) {
            userSessions.put(Long.parseLong(userId), session);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.remove(session);
        // Supprimer la session de l'utilisateur
        userSessions.values().remove(session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            Map<String, Object> data = mapper.readValue(message.getPayload(), Map.class);
            
            String type = (String) data.get("type");
            
            switch (type) {
                case "JOIN_CHAT":
                    handleJoinChat(session, data);
                    break;
                case "SEND_MESSAGE":
                    handleSendMessage(session, data);
                    break;
                case "TYPING":
                    handleTyping(session, data);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void handleJoinChat(WebSocketSession session, Map<String, Object> data) {
        Long userId = Long.parseLong(data.get("userId").toString());
        userSessions.put(userId, session);
        
        // Envoyer confirmation
        try {
            Map<String, Object> response = new HashMap<>();
            response.put("type", "JOIN_CONFIRMED");
            response.put("userId", userId);
            
            ObjectMapper mapper = new ObjectMapper();
            session.sendMessage(new TextMessage(mapper.writeValueAsString(response)));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void handleSendMessage(WebSocketSession session, Map<String, Object> data) {
        // Cette méthode sera appelée par le service MessageService
        // Pas besoin de traitement ici car les messages sont gérés via REST API
    }

    private void handleTyping(WebSocketSession session, Map<String, Object> data) {
        Long reservationId = Long.parseLong(data.get("reservationId").toString());
        Long userId = Long.parseLong(data.get("userId").toString());
        boolean isTyping = (Boolean) data.get("isTyping");
        
        // Notifier les autres participants du chat
        notifyTypingStatus(reservationId, userId, isTyping);
    }

    public void notifyNewMessage(String messageJson, Long destinataireId) {
        WebSocketSession destinataireSession = userSessions.get(destinataireId);
        if (destinataireSession != null && destinataireSession.isOpen()) {
            try {
                destinataireSession.sendMessage(new TextMessage(messageJson));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public void notifyTypingStatus(Long reservationId, Long userId, boolean isTyping) {
        // Notifier tous les utilisateurs connectés au chat de cette réservation
        for (WebSocketSession session : sessions) {
            if (session.isOpen()) {
                try {
                    Map<String, Object> notification = new HashMap<>();
                    notification.put("type", "TYPING_STATUS");
                    notification.put("reservationId", reservationId);
                    notification.put("userId", userId);
                    notification.put("isTyping", isTyping);
                    
                    ObjectMapper mapper = new ObjectMapper();
                    session.sendMessage(new TextMessage(mapper.writeValueAsString(notification)));
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private String extractUserIdFromSession(WebSocketSession session) {
        // Extraire l'ID utilisateur de l'URL de session
        String uri = session.getUri().toString();
        if (uri.contains("userId=")) {
            return uri.split("userId=")[1].split("&")[0];
        }
        return null;
    }
} 