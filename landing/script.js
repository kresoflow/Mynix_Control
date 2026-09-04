/**
 * ZUDRASON LUXURY EDITORIAL — SCRIPT
 * Bilingual Support (TJ / RU) & Direct WhatsApp Order Dispatcher
 */

document.addEventListener('DOMContentLoaded', () => {
  const i18n = {
    tj: {
      navServices: 'Хизматрасонӣ',
      navTariffs: 'Тарифҳо',
      navOrder: 'Фармоиш',
      navAbout: 'Дар бораи мо',
      heroTag: 'ХИЗМАТРАСОНИИ ФАВРӢ ДАР Ш. КӮЛОБ',
      heroTitle: 'PREMIUM EXPRESS <br><span class="hero-title-serif">ДОСТАВКА ВА ХАРИД</span>',
      heroDesc: 'Хӯроки гарм аз беҳтарин тарабхонаҳо, гулдастаҳои тоза ва хариди фаврӣ аз бозор. Эҳтиёткорона, тоза ва сари вақт дар 15–25 дақиқа рост ба дастатон.',
      btnCallHero: 'Занг задан: 119 17 17 17',
      metaStart: 'Тарифи ибтидоӣ',
      metaMins: 'Дақиқа вақти расонидан',
      metaHours: 'Ҳамарӯза бе истироҳат',
      servicesEyebrow: 'ХИЗМАТРАСОНИҲО',
      servicesHeading: 'Чиро мерасонем?',
      s1Title: 'Хӯрок аз ошхона ва тарабхонаҳо',
      s1Desc: 'Шашлик, ош, фастфуд ва қаҳваи гарм аз дилхоҳ ошхонаи шаҳри Кӯлоб бо нигоҳдории ҳарорат.',
      s2Title: 'Гулҳо ва Тӯҳфаҳо',
      s2Desc: 'Гулдастаҳои тару тоза ва тӯҳфаҳо барои зодрӯзу ҷашнҳо бо расонидани боэҳтиёт ба қабулкунанда.',
      s3Title: 'Харид аз бозор ва мағозаҳо',
      s3Desc: 'Рӯйхати маводҳои хӯрока ё доруҳои лозимаро фиристед — мо худамон интихоб ва харидорӣ мекунем.',
      rateFrom: 'Аз 10 сомонӣ',
      btnOrderFood: 'Фармоиши хӯрок',
      btnOrderFlowers: 'Фармоиши гул',
      btnOrderMarket: 'Фармоиши харид',
      tariffsEyebrow: 'НАРХНОМАИ РАСМӢ',
      tariffsHeading: 'Тарифҳои нақлиёт',
      t1Name: 'Скутер',
      t1Meta: 'Хӯрок, гулҳо, доруворӣ',
      t2Name: 'Автомобил',
      t2Meta: 'Борҳои калонтар, ҳавои боронӣ',
      t3Name: 'Моторолик',
      t3Meta: 'Қуттиҳо ва харидҳои калон',
      t4Name: 'Мошини боркаш',
      t4Meta: 'Борҳои вазнин, мебел, сохтмон',
      inCityLabel: 'Дохили шаҳр:',
      outCityLabel: 'Берун аз шаҳр:',
      btnSelect: 'Интихоб',
      orderEyebrow: 'ФАРМОИШИ ФАВРӢ',
      orderHeading: 'Тайёр кардани фармоиш барои WhatsApp',
      orderDesc: 'Маълумотро интихоб кунед — паём ба таври автоматӣ омода шуда, дар WhatsApp кушода мешавад.',
      f1Label: 'Намуди бор / харид:',
      f2Label: 'Минтақа:',
      f3Label: 'Нақлиёт:',
      f4Label: 'Аз куҷо (суроға ё номи мағоза):',
      f5Label: 'Ба куҷо (суроғаи қабулкунанда):',
      btnSendWa: 'Фармоиш дар WhatsApp',
      orCallLabel: 'Ё занги мустақим:',
      fTagline: 'Хизматрасонии расмии экспресс-доставка дар шаҳри Кӯлоб. Суръат, тозагӣ ва эътимоди 100%.',
      fCol1Title: 'Хизматрасонӣ',
      fLink1: 'Хӯроки тарабхона',
      fLink2: 'Гулҳо ва тӯҳфаҳо',
      fLink3: 'Хариди бозор',
      fLink4: 'Доруворӣ ва аптека',
      fCol2Title: 'Тарифҳо',
      fLink5: 'Скутер (10 с)',
      fLink6: 'Автомобил (15 с)',
      fLink7: 'Моторолик (20 с)',
      fLink8: 'Мошини боркаш (50 с)',
      fCol3Title: 'Тамос',
      fCity: '📍 ш. Кӯлоб, Тоҷикистон',
      fCopyright: '© 2026 ZUDRASON ДОСТАВКА. Ҳамаи ҳуқуқҳо ҳифз шудаанд.',
      fCityTag: 'Шаҳри Кӯлоб'
    },
    ru: {
      navServices: 'Услуги',
      navTariffs: 'Тарифы',
      navOrder: 'Заказ',
      navAbout: 'О сервисе',
      heroTag: 'СЛУЖБА ЭКСПРЕСС-ДОСТАВКИ В Г. КУЛЯБ',
      heroTitle: 'PREMIUM EXPRESS <br><span class="hero-title-serif">ДОСТАВКА И ПОКУПКИ</span>',
      heroDesc: 'Горячая еда из лучших ресторанов, свежие цветы и срочные покупки на базаре. Бережно, чисто и вовремя за 15–25 минут прямо в руки.',
      btnCallHero: 'Позвонить: 119 17 17 17',
      metaStart: 'Стартовый тариф',
      metaMins: 'Минут среднее время',
      metaHours: 'Ежедневно без выходных',
      servicesEyebrow: 'НАШИ УСЛУГИ',
      servicesHeading: 'Что мы доставляем?',
      s1Title: 'Еда из ресторанов и кафе',
      s1Desc: 'Шашлык, плов, фастфуд и горячий кофе из любого заведения Куляба с термосумкой.',
      s2Title: 'Цветы и подарки',
      s2Desc: 'Свежие букеты и подарки на праздники с деликатной передачей лично получателю.',
      s3Title: 'Покупки на базаре и в магазинах',
      s3Desc: 'Отправьте список продуктов или лекарств — мы лично выберем лучшее и привезем.',
      rateFrom: 'От 10 сомони',
      btnOrderFood: 'Заказать еду',
      btnOrderFlowers: 'Заказать цветы',
      btnOrderMarket: 'Заказать покупку',
      tariffsEyebrow: 'ОФИЦИАЛЬНЫЙ ПРАЙС',
      tariffsHeading: 'Тарифы на транспорт',
      t1Name: 'Скутер',
      t1Meta: 'Еда, цветы, лекарства',
      t2Name: 'Автомобиль',
      t2Meta: 'Крупные покупки, непогода',
      t3Name: 'Мотороллер',
      t3Meta: 'Коробки и объемный груз',
      t4Name: 'Грузовой авто',
      t4Meta: 'Тяжелый груз, мебель, стройматериалы',
      inCityLabel: 'По городу:',
      outCityLabel: 'За город:',
      btnSelect: 'Выбрать',
      orderEyebrow: 'БЫСТРЫЙ ЗАКАЗ',
      orderHeading: 'Сформировать заказ для WhatsApp',
      orderDesc: 'Выберите параметры — готовый текст автоматически откроется в чате WhatsApp.',
      f1Label: 'Что доставить:',
      f2Label: 'Зона:',
      f3Label: 'Транспорт:',
      f4Label: 'Откуда (адрес или заведение):',
      f5Label: 'Куда (адрес получателя):',
      btnSendWa: 'Заказать в WhatsApp',
      orCallLabel: 'Или звоните напрямую:',
      fTagline: 'Официальная служба экспресс-доставки в г. Куляб. Скорость, чистота и 100% надежность.',
      fCol1Title: 'Услуги',
      fLink1: 'Еда из ресторанов',
      fLink2: 'Цветы и подарки',
      fLink3: 'Покупки на базаре',
      fLink4: 'Аптека и лекарства',
      fCol2Title: 'Тарифы',
      fLink5: 'Скутер (10 с)',
      fLink6: 'Автомобиль (15 с)',
      fLink7: 'Мотороллер (20 с)',
      fLink8: 'Грузовик (50 с)',
      fCol3Title: 'Контакты',
      fCity: '📍 г. Куляб, Таджикистан',
      fCopyright: '© 2026 ZUDRASON ДОСТАВКА. Все права защищены.',
      fCityTag: 'г. Куляб'
    }
  };

  let currentLang = 'tj';

  // Language Switcher
  const langOpts = document.querySelectorAll('.lang-opt');
  langOpts.forEach(btn => {
    btn.addEventListener('click', () => {
      const lang = btn.dataset.lang;
      if (lang === currentLang) return;

      currentLang = lang;
      langOpts.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      document.documentElement.lang = lang;

      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (i18n[lang] && i18n[lang][key]) {
          el.innerHTML = i18n[lang][key];
        }
      });
    });
  });

  // WhatsApp Order Submission
  const submitWaBtn = document.getElementById('submitWaBtn');
  if (submitWaBtn) {
    submitWaBtn.addEventListener('click', () => {
      const item = document.getElementById('itemSelect')?.value || 'Хӯрок';
      const zone = document.getElementById('zoneSelect')?.value || 'Дохили шаҳр';
      const transport = document.getElementById('transportSelect')?.value || 'Скутер';
      const from = document.getElementById('fromInput')?.value?.trim();
      const to = document.getElementById('toInput')?.value?.trim();

      if (!from || !to) {
        alert(currentLang === 'tj' 
          ? 'Лутфан, суроғаи забор ва суроғаи қабулкунандаро нависед!' 
          : 'Пожалуйста, укажите адрес забора и адрес доставки!');
        return;
      }

      const text = currentLang === 'tj'
        ? `Салом, Zudrason Luxury Delivery!\nМехоҳам фармоиш диҳам:\n\n🍽️ Бор / Харид: ${item}\n🏙️ Минтақа: ${zone}\n🛵 Нақлиёт: ${transport}\n📍 Аз куҷо: ${from}\n🏁 Ба куҷо: ${to}`
        : `Здравствуйте, Zudrason Luxury Delivery!\nХочу оформить заказ:\n\n🍽️ Покупка / Груз: ${item}\n🏙️ Зона: ${zone}\n🛵 Транспорт: ${transport}\n📍 Откуда: ${from}\n🏁 Куда: ${to}`;

      const waUrl = `https://wa.me/992119171717?text=${encodeURIComponent(text)}`;
      window.open(waUrl, '_blank');
    });
  }
});
