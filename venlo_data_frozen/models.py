from django.db import models

# Create your models here.


# class TransactionDT(models.Model):
#     created_dt = models.DateTimeField(auto_now_add=True, null=True, verbose_name='Gemaakt op')
#     modified_dt = models.DateTimeField(auto_now=True, null=True, verbose_name='Laatst gewijzigd op')
#     last_modified_user = models.ForeignKey('auth.User',
#                                            verbose_name='Laatst gewijzigd door',
#                                            null=True, blank=True,
#                                            on_delete=models.CASCADE)
#
#     class Meta:
#         abstract = True


class FrozenData(models.Model):
    yr = models.PositiveIntegerField()
    mnth = models.PositiveIntegerField()
    journaalpost = models.CharField(max_length=50,
                                    null=False,)
    amount = models.DecimalField(null=False, decimal_places=2, max_digits=10)

    class Meta:
        managed = False
        db_table = 'parkinganalysis.venlo_dw.journaalposten_frozen'

    def __str__(self):
        return f'{self.naam}'
