import asyncio
from typing import List
from fastapi import WebSocket


class ConnectionManager:
    """
    Manage active WebSocket connections and broadcast messages to all connected
    clients. A single global instance (`manager`) is used by the sensor service
    and any FastAPI route that wants to push updates.
    """

    def __init__(self) -> None:
        self.active_connections: List[WebSocket] = []
        self.lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket) -> None:
        """Accept a new client and add it to the list."""
        await websocket.accept()
        async with self.lock:
            self.active_connections.append(websocket)

    async def disconnect(self, websocket: WebSocket) -> None:
        """Remove a client when it closes the connection."""
        async with self.lock:
            if websocket in self.active_connections:
                self.active_connections.remove(websocket)

    async def broadcast(self, message: str) -> None:
        """Send `message` to every connected client."""
        async with self.lock:
            to_remove: List[WebSocket] = []
            for connection in self.active_connections:
                try:
                    await connection.send_text(message)
                except Exception:
                    # If sending fails the client is probably gone – schedule removal
                    to_remove.append(connection)

            for conn in to_remove:
                self.active_connections.remove(conn)


# Global singleton used throughout the project
manager = ConnectionManager()