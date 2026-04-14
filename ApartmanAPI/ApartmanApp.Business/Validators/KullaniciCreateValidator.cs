using ApartmanApp.Business.DTOs.Kullanici;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class KullaniciCreateValidator : AbstractValidator<KullaniciCreateDto>
{
    public KullaniciCreateValidator()
    {
        RuleFor(x => x.Ad)
            .NotEmpty().WithMessage("Ad boş olamaz.")
            .MaximumLength(50).WithMessage("Ad en fazla 50 karakter olabilir.");

        RuleFor(x => x.Soyad)
            .NotEmpty().WithMessage("Soyad boş olamaz.")
            .MaximumLength(50).WithMessage("Soyad en fazla 50 karakter olabilir.");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email boş olamaz.")
            .EmailAddress().WithMessage("Geçerli bir email adresi giriniz.")
            .MaximumLength(100).WithMessage("Email en fazla 100 karakter olabilir.");

        RuleFor(x => x.DaireNo)
            .NotEmpty().WithMessage("Daire No boş olamaz.")
            .MaximumLength(10).WithMessage("Daire No en fazla 10 karakter olabilir.");

        RuleFor(x => x.Rol)
            .IsInEnum().WithMessage("Geçersiz rol değeri.");

        RuleFor(x => x.Sifre)
            .NotEmpty().WithMessage("Şifre boş olamaz.")
            .MinimumLength(6).WithMessage("Şifre en az 6 karakter olmalıdır.");
    }
}
