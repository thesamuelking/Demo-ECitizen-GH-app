from rest_framework import serializers
from .models import CitizenUser


class UserSerializer(serializers.ModelSerializer):
    has_ghanacard = serializers.SerializerMethodField()

    class Meta:
        model = CitizenUser
        fields = ('id', 'full_name', 'email', 'phone', 'ghanacard_number', 'has_ghanacard', 'profile_photo', 'is_verified', 'is_staff', 'service_department', 'created_at')
        read_only_fields = ('id', 'ghanacard_number', 'is_verified', 'is_staff', 'service_department', 'created_at')

    def get_has_ghanacard(self, obj):
        return bool(obj.ghanacard_number)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['is_verified'] = bool(instance.is_verified or instance.ghanacard_number)
        return data


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = CitizenUser
        fields = ('full_name', 'email', 'phone', 'password', 'ghanacard_number')

    def validate_ghanacard_number(self, value):
        return value.strip().upper() or None

    def create(self, validated_data):
        validated_data['is_verified'] = bool(validated_data.get('ghanacard_number'))
        return CitizenUser.objects.create_user(**validated_data)


class VerifyAccountSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=160)
    ghanacard_number = serializers.CharField(max_length=30)

    def validate_ghanacard_number(self, value):
        value = value.strip().upper()
        if not value:
            raise serializers.ValidationError('Ghana Card number is required.')
        return value
