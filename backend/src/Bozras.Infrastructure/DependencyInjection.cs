using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Application.Services;
using Bozras.Infrastructure.Notifications;
using Bozras.Infrastructure.Persistence.Data;
using Bozras.Infrastructure.Repositories;
using Bozras.Infrastructure.Services;
using Bozras.Infrastructure.Tenancy;

namespace Bozras.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
                               ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

        services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));

        services.Configure<JwtSettings>(configuration.GetSection(JwtSettings.SectionName));

        services.AddMemoryCache();
        services.AddSingleton<ICacheService, CacheService>();
        if (!string.IsNullOrWhiteSpace(configuration["Email:BrevoApiKey"]))
            services.AddHttpClient<IEmailSender, BrevoEmailSender>();
        else
            services.AddSingleton<IEmailSender, LogEmailSender>();

        services.AddSingleton<IPasswordService, PasswordService>();
        services.AddSingleton<IJwtTokenGenerator, JwtTokenGenerator>();

        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IShopRepository, ShopRepository>();

        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IShopService, ShopService>();
        
        services.AddSingleton(TimeProvider.System);

        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<ISettingRepository, SettingRepository>();

        services.AddScoped<IOrderService, OrderService>();
        
        services.AddScoped<IPaymentRepository, PaymentRepository>();

        services.AddScoped<IDebtService, DebtService>();
        services.AddScoped<IPaymentService, PaymentService>();
        
        services.AddScoped<IReportRepository, ReportRepository>();
        services.AddScoped<IReportService, ReportService>();
        
        services.AddScoped<IVisitRepository, VisitRepository>();
        services.AddScoped<IVisitService, VisitService>();
        
        services.AddScoped<ISettingService, SettingService>();
        
        services.AddScoped<IUserAccessService, UserAccessService>();
        
        services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
        
        services.AddSingleton<PushQueue>();
        services.AddSingleton<IPushQueue>(sp => sp.GetRequiredService<PushQueue>());
        services.AddHostedService<PushDispatcher>();

        var firebaseConfigured =
            !string.IsNullOrWhiteSpace(configuration["Firebase:CredentialsJson"]) ||
            !string.IsNullOrWhiteSpace(configuration["Firebase:CredentialsPath"]);

        if (firebaseConfigured)
            services.AddSingleton<IPushSender, FcmPushSender>();
        else
            services.AddSingleton<IPushSender, LogPushSender>();

        services.AddScoped<IOrderNotifier, OrderNotifier>();
        services.AddScoped<IDeviceService, DeviceService>();
        
        services.AddScoped<ICategoryRepository, CategoryRepository>();
        services.AddScoped<IStockRepository, StockRepository>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddScoped<IStockService, StockService>();
        
        services.AddScoped<ITenantContext, TenantContext>();
        services.AddScoped<ITenantAccessService, TenantAccessService>();
        
        services.AddScoped<ISupplierRepository, SupplierRepository>();
        services.AddScoped<IPlanRepository, PlanRepository>();
        services.AddScoped<ILocationRepository, LocationRepository>();
        services.AddScoped<ISupplierService, SupplierService>();
        services.AddScoped<IPlanService, PlanService>();
        services.AddScoped<ILocationService, LocationService>();
        
        services.AddScoped<IConnectionRepository, ConnectionRepository>();
        services.AddScoped<IShopConnectionService, ShopConnectionService>();
        services.AddScoped<ISupplierProfileService, SupplierProfileService>();
        
        services.AddScoped<IPlanLimitService, PlanLimitService>();
        services.AddScoped<IShopRequestNotifier, ShopRequestNotifier>();
        
        return services;
    }
}