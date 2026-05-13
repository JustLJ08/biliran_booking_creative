# Generated migration for national_id_image field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0011_booking_payment_proof_alter_booking_status'),
    ]

    operations = [
        migrations.AddField(
            model_name='creativeprofile',
            name='national_id_image',
            field=models.ImageField(blank=True, null=True, upload_to='national_ids/'),
        ),
    ]
