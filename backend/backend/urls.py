# backend/urls.py
from django.contrib import admin
from django.urls import path
from game import views

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Endpoints (todos cumplen con los requisitos)
    path('api/register/', views.RegisterView.as_view(), name='register'),
    path('api/login/', views.LoginView.as_view(), name='login'),
    path('api/verify/', views.VerifyTokenView.as_view(), name='verify'),
    path('api/saves/', views.GetSaveSlotsView.as_view(), name='get_saves'),
    path('api/saves/<int:slot_number>/', views.GetSaveSlotView.as_view(), name='get_save'),
    path('api/saves/<int:slot_number>/create/', views.CreateSaveSlotView.as_view(), name='create_save'),
    path('api/saves/<int:slot_number>/update/', views.UpdateSaveSlotView.as_view(), name='update_save'),
    path('api/saves/<int:slot_number>/delete/', views.DeleteSaveSlotView.as_view(), name='delete_save'),
    path('api/unlock-upgrade/', views.UnlockUpgradeView.as_view(), name='unlock_upgrade'),
]