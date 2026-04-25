using ApartmanApp.Business.DTOs.Kullanici;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class SifreGuncelleValidator : AbstractValidator<SifreGuncelleDto>
{
    public SifreGuncelleValidator()
    {
        RuleFor(x => x.EskiSifre)
            .NotEmpty().WithMessage("Mevcut şifre zorunludur.");

        RuleFor(x => x.YeniSifre).StrongPassword();

        RuleFor(x => x.YeniSifre)
            .NotEqual(x => x.EskiSifre)
            .WithMessage("Yeni şifre eskisiyle aynı olamaz.");
    }
}

public class AdminSifreSifirlaValidator : AbstractValidator<AdminSifreSifirlaDto>
{
    public AdminSifreSifirlaValidator()
    {
        RuleFor(x => x.YeniSifre).StrongPassword();
    }
}
