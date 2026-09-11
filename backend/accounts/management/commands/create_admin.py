from django.core.management.base import BaseCommand, CommandError
from accounts.models import CitizenUser


class Command(BaseCommand):
    help = 'Create or update an authorized E-citizen GH government staff account.'

    def add_arguments(self, parser):
        parser.add_argument('--email', required=True)
        parser.add_argument(
            '--old-email',
            help='Existing staff email to rename when changing an account email.',
        )
        parser.add_argument('--password', required=True)
        parser.add_argument('--name', required=True)
        parser.add_argument('--phone', default='')
        parser.add_argument(
            '--service',
            required=True,
            choices=[value for value, _ in CitizenUser.SERVICE_DEPARTMENTS],
            help='Service department assigned to this staff account.',
        )

    def handle(self, *args, **options):
        email = options['email'].strip().lower()
        if not email.endswith('@ecitizengh.com'):
            raise CommandError('Admin email must end with @ecitizengh.com.')
        old_email = (options.get('old_email') or '').strip().lower()
        if old_email and not old_email.endswith('@ecitizengh.com'):
            raise CommandError('Old admin email must end with @ecitizengh.com.')

        if old_email:
            try:
                user = CitizenUser.objects.get(email=old_email)
            except CitizenUser.DoesNotExist as error:
                raise CommandError(f'No account exists for --old-email {old_email}.') from error
            if CitizenUser.objects.filter(email=email).exclude(pk=user.pk).exists():
                raise CommandError(f'Another account already uses {email}.')
            created = False
        else:
            user, created = CitizenUser.objects.get_or_create(email=email, defaults={
                'full_name': options['name'], 'phone': options['phone'], 'is_staff': True,
            })

        user.email = email
        user.full_name = options['name']
        user.phone = options['phone']
        user.service_department = options['service']
        user.is_staff = True
        user.is_active = True
        user.set_password(options['password'])
        user.save()
        action = 'Created' if created else 'Updated'
        self.stdout.write(self.style.SUCCESS(f'{action} staff account {email}'))