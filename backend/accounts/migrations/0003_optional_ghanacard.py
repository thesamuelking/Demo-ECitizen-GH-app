from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('accounts', '0002_alter_citizenuser_profile_photo')]

    operations = [
        migrations.AlterField(
            model_name='citizenuser',
            name='ghanacard_number',
            field=models.CharField(blank=True, max_length=30, null=True, unique=True),
        ),
    ]
