# game/models.py
from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid
import hashlib
import secrets


class Player(AbstractUser):
    """Modelo de jugador (tabla 1)"""
    # Añadir related_name para evitar conflictos
    groups = models.ManyToManyField(
        'auth.Group',
        related_name='player_groups',  # Cambiado
        blank=True,
        verbose_name='groups',
        help_text='The groups this user belongs to.'
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='player_permissions',  # Cambiado
        blank=True,
        verbose_name='user permissions',
        help_text='Specific permissions for this user.'
    )

    total_stars = models.IntegerField(default=0)
    total_fragments = models.IntegerField(default=0)
    session_token = models.CharField(max_length=255, null=True, blank=True, unique=True)
    session_created_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def generate_session_token(self, password):
        """Genera token de sesión salteado"""
        salt = secrets.token_hex(16)
        combined = f"{self.username}:{password}:{salt}"
        token = hashlib.sha256(combined.encode()).hexdigest()
        self.session_token = token
        return token

    def __str__(self):
        return self.username


class SaveSlot(models.Model):
    """Modelo de ranura de guardado (tabla 2) - relación N:1 con Player"""
    SLOT_CHOICES = [(1, 'Slot 1'), (2, 'Slot 2'), (3, 'Slot 3')]

    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name='save_slots')
    slot_number = models.IntegerField(choices=SLOT_CHOICES)

    # Datos del juego
    level_up_count = models.IntegerField(default=0)
    x2_active = models.BooleanField(default=False)
    stars = models.IntegerField(default=0)
    fragments = models.IntegerField(default=10)
    experiencia = models.FloatField(default=0.0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['player', 'slot_number']

    def __str__(self):
        return f"{self.player.username} - Slot {self.slot_number}"


class Upgrade(models.Model):
    """Modelo de mejora (tabla 3) - relación N:N con SaveSlot"""
    UPGRADE_TYPES = [
        ('agilidad', 'Agilidad'),
        ('vida', 'Vida'),
        ('danho', 'Daño'),
        ('especial', 'Especial'),
    ]

    upgrade_id = models.CharField(max_length=50, unique=True)
    upgrade_name = models.CharField(max_length=100)
    upgrade_type = models.CharField(max_length=20, choices=UPGRADE_TYPES)
    level = models.IntegerField(default=1)
    precio_base = models.IntegerField(default=3)

    def __str__(self):
        return self.upgrade_name


class SaveSlotUpgrade(models.Model):
    """Tabla intermedia para relación N:N entre SaveSlot y Upgrade"""
    save_slot = models.ForeignKey(SaveSlot, on_delete=models.CASCADE, related_name='upgrades')
    upgrade = models.ForeignKey(Upgrade, on_delete=models.CASCADE)
    unlocked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['save_slot', 'upgrade']

    def __str__(self):
        return f"{self.save_slot} - {self.upgrade}"