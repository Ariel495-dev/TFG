# game/views.py
import json
from django.shortcuts import get_object_or_404
from django.contrib.auth import authenticate
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Player, SaveSlot, Upgrade, SaveSlotUpgrade
from .serializers import (
    PlayerSerializer, PlayerRegisterSerializer,
    SaveSlotSerializer, UpgradeSerializer
)


def get_player_from_token(token):
    """Helper para obtener jugador por token"""
    try:
        return Player.objects.get(session_token=token)
    except Player.DoesNotExist:
        return None


# ============ 1. REGISTRO - POST con body JSON ============
class RegisterView(APIView):
    def post(self, request):
        serializer = PlayerRegisterSerializer(data=request.data)
        if serializer.is_valid():
            player = serializer.save()
            # Generar token de sesión
            token = player.generate_session_token(request.data['password'])
            player.save()
            return Response({
                'success': True,
                'user_id': player.id,
                'username': player.username,
                'session_token': token
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ============ 2. LOGIN - POST con body JSON ============
class LoginView(APIView):
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        player = authenticate(username=username, password=password)
        if player:
            token = player.generate_session_token(password)
            player.save()
            return Response({
                'success': True,
                'user_id': player.id,
                'username': player.username,
                'session_token': token
            })
        return Response({'error': 'Credenciales inválidas'}, status=status.HTTP_401_UNAUTHORIZED)


# ============ 3. VERIFICAR TOKEN - GET con query params ============
class VerifyTokenView(APIView):
    def get(self, request):
        # Query param: ?token=xxx
        token = request.query_params.get('token')
        if not token:
            return Response({'valid': False, 'error': 'Token requerido'}, status=status.HTTP_400_BAD_REQUEST)

        player = get_player_from_token(token)
        if player:
            return Response({'valid': True, 'user_id': player.id, 'username': player.username})
        return Response({'valid': False}, status=status.HTTP_401_UNAUTHORIZED)


# ============ 4. OBTENER RANURAS - GET con query params ============
class GetSaveSlotsView(APIView):
    def get(self, request):
        # Query params: ?token=xxx
        token = request.query_params.get('token')
        player = get_player_from_token(token)

        if not player:
            return Response({'error': 'Sesión inválida'}, status=status.HTTP_401_UNAUTHORIZED)

        slots = SaveSlot.objects.filter(player=player)
        serializer = SaveSlotSerializer(slots, many=True)
        return Response({'slots': serializer.data})


# ============ 5. OBTENER RANURA ESPECÍFICA - GET con path param y query params ============
class GetSaveSlotView(APIView):
    def get(self, request, slot_number):
        # Path param: slot_number
        # Query params: ?token=xxx
        token = request.query_params.get('token')
        player = get_player_from_token(token)

        if not player:
            return Response({'error': 'Sesión inválida'}, status=status.HTTP_401_UNAUTHORIZED)

        slot = get_object_or_404(SaveSlot, player=player, slot_number=slot_number)
        serializer = SaveSlotSerializer(slot)

        # Obtener mejoras desbloqueadas
        upgrades = SaveSlotUpgrade.objects.filter(save_slot=slot).select_related('upgrade')
        upgrades_data = [{'upgrade_id': u.upgrade.upgrade_id, 'unlocked_at': u.unlocked_at} for u in upgrades]

        return Response({
            'slot': serializer.data,
            'upgrades': upgrades_data
        })


# ============ 6. CREAR RANURA - POST con path param y body JSON ============
class CreateSaveSlotView(APIView):
    def post(self, request, slot_number):
        # Path param: slot_number
        # Body: {"token": "xxx", "level_up_count": 0, ...}
        token = request.data.get('token')
        player = get_player_from_token(token)

        if not player:
            return Response({'error': 'Sesión inválida'}, status=status.HTTP_401_UNAUTHORIZED)

        if SaveSlot.objects.filter(player=player, slot_number=slot_number).exists():
            return Response({'error': 'La ranura ya existe'}, status=status.HTTP_400_BAD_REQUEST)

        slot = SaveSlot.objects.create(
            player=player,
            slot_number=slot_number,
            level_up_count=request.data.get('level_up_count', 0),
            x2_active=request.data.get('x2_active', False),
            stars=request.data.get('stars', 0),
            fragments=request.data.get('fragments', 10)
        )

        return Response({'success': True, 'slot': slot.slot_number}, status=status.HTTP_201_CREATED)


# ============ 7. ACTUALIZAR RANURA - PUT con path param, query params y body ============
class UpdateSaveSlotView(APIView):
    def put(self, request, slot_number):
        # Path param: slot_number
        # Query params: ?token=xxx&partial=true
        token = request.query_params.get('token')
        partial = request.query_params.get('partial', 'false').lower() == 'true'

        player = get_player_from_token(token)
        if not player:
            return Response({'error': 'Sesión inválida'}, status=status.HTTP_401_UNAUTHORIZED)

        slot = get_object_or_404(SaveSlot, player=player, slot_number=slot_number)

        if partial:
            # Actualización parcial
            if 'level_up_count' in request.data:
                slot.level_up_count = request.data['level_up_count']
            if 'x2_active' in request.data:
                slot.x2_active = request.data['x2_active']
            if 'stars' in request.data:
                slot.stars = request.data['stars']
            if 'fragments' in request.data:
                slot.fragments = request.data['fragments']
            if 'experiencia' in request.data:
                slot.experiencia = request.data['experiencia']
        else:
            # Actualización completa
            slot.level_up_count = request.data.get('level_up_count', slot.level_up_count)
            slot.x2_active = request.data.get('x2_active', slot.x2_active)
            slot.stars = request.data.get('stars', slot.stars)
            slot.fragments = request.data.get('fragments', slot.fragments)
            slot.experiencia = request.data.get('experiencia', slot.experiencia)

        slot.save()

        # Actualizar totales del jugador
        player.total_stars = sum(s.stars for s in player.save_slots.all())
        player.total_fragments = sum(s.fragments for s in player.save_slots.all())
        player.save()

        return Response({'success': True, 'message': 'Ranura actualizada'})


# ============ 8. ELIMINAR RANURA - DELETE con path param y query params ============
class DeleteSaveSlotView(APIView):
    def delete(self, request, slot_number):
        # Path param: slot_number
        # Query params: ?token=xxx&confirm=true
        token = request.query_params.get('token')
        confirm = request.query_params.get('confirm', 'false').lower() == 'true'

        if not confirm:
            return Response({'error': 'Se requiere confirmación (confirm=true)'}, status=status.HTTP_400_BAD_REQUEST)

        player = get_player_from_token(token)
        if not player:
            return Response({'error': 'Sesión inválida'}, status=status.HTTP_401_UNAUTHORIZED)

        slot = get_object_or_404(SaveSlot, player=player, slot_number=slot_number)
        slot.delete()

        return Response({'success': True, 'message': f'Ranura {slot_number} eliminada'})


# ============ 9. DESBLOQUEAR MEJORA - POST con body JSON ============
class UnlockUpgradeView(APIView):
    def post(self, request):
        # Body: {"token": "xxx", "slot_number": 1, "upgrade_id": "agilidad1"}
        token = request.data.get('token')
        slot_number = request.data.get('slot_number')
        upgrade_id = request.data.get('upgrade_id')

        player = get_player_from_token(token)
        if not player:
            return Response({'error': 'Sesión inválida'}, status=status.HTTP_401_UNAUTHORIZED)

        slot = get_object_or_404(SaveSlot, player=player, slot_number=slot_number)
        upgrade = get_object_or_404(Upgrade, upgrade_id=upgrade_id)

        # Verificar si ya está desbloqueada
        if SaveSlotUpgrade.objects.filter(save_slot=slot, upgrade=upgrade).exists():
            return Response({'error': 'Mejora ya desbloqueada'}, status=status.HTTP_400_BAD_REQUEST)

        SaveSlotUpgrade.objects.create(save_slot=slot, upgrade=upgrade)

        return Response({'success': True, 'message': f'Mejora {upgrade_id} desbloqueada'})