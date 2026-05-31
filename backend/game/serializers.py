# game/serializers.py
from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import Player, SaveSlot, Upgrade, SaveSlotUpgrade


class PlayerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Player
        fields = ['id', 'username', 'total_stars', 'total_fragments', 'created_at']
        read_only_fields = ['id', 'created_at']


class PlayerRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = Player
        fields = ['username', 'password', 'password_confirm']

    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError("Las contraseñas no coinciden")
        return data

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        validated_data['password'] = make_password(validated_data['password'])
        return super().create(validated_data)


class SaveSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = SaveSlot
        fields = ['slot_number', 'level_up_count', 'x2_active', 'stars', 'fragments', 'experiencia', 'updated_at']


class UpgradeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Upgrade
        fields = ['upgrade_id', 'upgrade_name', 'upgrade_type', 'level', 'precio_base']


class SaveSlotUpgradeSerializer(serializers.ModelSerializer):
    upgrade_info = UpgradeSerializer(source='upgrade', read_only=True)

    class Meta:
        model = SaveSlotUpgrade
