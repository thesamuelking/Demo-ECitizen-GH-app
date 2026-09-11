from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):
    dependencies = [('applications', '0001_initial')]

    operations = [
        migrations.AlterField(
            model_name='citizenapplication', name='status',
            field=models.CharField(choices=[('draft', 'Draft'), ('pending', 'Pending'), ('processing', 'Processing'), ('approved', 'Approved'), ('rejected', 'Rejected'), ('ready', 'Ready')], default='draft', max_length=20),
        ),
        migrations.CreateModel(
            name='ApplicationNotification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=160)),
                ('message', models.TextField()),
                ('is_read', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='application_notifications', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ('-created_at',)},
        ),
    ]