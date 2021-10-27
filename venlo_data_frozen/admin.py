from django.contrib import admin

from venlo_data_frozen.models import FrozenData


@admin.register(FrozenData)
class FrozenDataAdmin(admin.ModelAdmin):
    list_per_page = 100
    list_display = ('yr', 'mnth', 'journaalpost')
    list_filter = list_display
    list_display_links = list_display
    ordering = list_display
    # search_fields = ('klant__name', 'naam')

    fieldsets = (
        ('Key waarden', {
            'classes': ('wide', 'extrapretty'),
            'fields': ('yr', 'mnth', 'journaalpost' )
        }),
        ('Bijzonderheden', {
            'classes': ('wide', 'extrapretty'),
            'fields': ('amount', ),
        }),
    )